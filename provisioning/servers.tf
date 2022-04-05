#########################################################################################################
################# This script create an ASG and balancer to execute the application #####################
#########################################################################################################

########################## ALB Security Group ########################################################### 
module "alb_service_sg" {
    source                      = "terraform-aws-modules/security-group/aws"
    name                        = "user-service"
    description                 = "Security Group for user-service with custom ports"
    vpc_id                      = module.vpc.vpc_id

    ingress_cidr_blocks         = var.whitelist
    ingress_with_cidr_blocks    = [
        {
            from_port           = 80
            to_port             = 80
            protocol            = "tcp"
            description         = "user-service port"
            cidr_blocks         = var.internet_access
        }
    ]

    egress_cidr_blocks          = var.whitelist
    egress_with_cidr_blocks     = [
        {
            from_port           = 0
            to_port             = 0
            protocol            = "-1"
            description         = "user_service port"
            cidr_blocks         = var.internet_access
        }
    ] 

}

########################## EC2 INSTANCE SECURITY GROUP #################################################
resource "aws_security_group" "ec2instances_sg" {
    name                        = "SG-ec2"
    description                 = "Security Group for EC2 Instances"
    vpc_id                      = module.vpc.vpc_id
    depends_on = [
        module.alb_service_sg
    ]

    ingress                     = [
        {
            description         = "Access to 80 port from load balancer"
            from_port           = 80
            to_port             = 80
            protocol            = "tcp"
            security_groups     = [module.alb_service_sg.security_group_id]
            self                = false
            cidr_blocks         = []
            ipv6_cidr_blocks    = []
            prefix_list_ids     = []        
        },
        {
            description         = "Access to 80 port from load balancer"
            from_port           = 9990
            to_port             = 9990
            protocol            = "tcp"
            security_groups     = [module.alb_service_sg.security_group_id]
            self                = false
            cidr_blocks         = []
            ipv6_cidr_blocks    = []
            prefix_list_ids     = []        
        }
    ]

    egress                      = [
        {
            description         = "Internet output instances access"
            from_port           = 443
            to_port             = 443
            protocol            = "tcp"
            cidr_blocks         = [var.internet_access]
            ipv6_cidr_blocks    = [var.ipv6_cidr_ia]
            self                = false
            security_groups     = []
            prefix_list_ids     = []
        },
        {
            description         = "Internet output instances access"
            from_port           = 80
            to_port             = 80
            protocol            = "tcp"
            cidr_blocks         = [var.internet_access]
            ipv6_cidr_blocks    = [var.ipv6_cidr_ia]
            self                = false
            security_groups     = []
            prefix_list_ids     = []
        }
    ]      
}

########################### Application Load Balancer creation ##########################################
module "alb" {
    source                      = "terraform-aws-modules/alb/aws"
    version                     = "~> 6.0"
    name                        = "balancer"
    depends_on = [
        module.vpc , module.alb_service_sg, module.s3_bucket
    ]

    load_balancer_type          = "application"

    vpc_id                      = module.vpc.vpc_id
    subnets                     = module.vpc.public_subnets
    security_groups             = [module.alb_service_sg.security_group_id]

    access_logs                 = {
        bucket                  = "aws-balancer-002580115597"
    }

    target_groups = [
        {
            name_prefix         = "pref-"
            backend_protocol    = "HTTP"
            backend_port        = 9990
            target_type         = "instance"
            targets             = []
            vpc_id              = module.vpc.vpc_id
        }
    ]

    http_tcp_listeners = [
        {
            port                = 80
            protocol            = "HTTP"
            target_group_index  = 0
        }
    ]

    tags = {
        functionality      : "application"
    }
}

########################### LAUNCH TEMPLATE DEFINITION ##################################################
resource "aws_launch_template" "tf_ec2template" {
    name                        = "tf_ec2lachuntemplate"

    block_device_mappings {
        device_name             = "/dev/xvda"

    ebs {
        volume_size             = 32
        volume_type             = "gp3"
        encrypted               = true
        }
    }

    image_id                    = "ami-06c73a8827b372409" //ami-0788c960a796ad0e8 - ami-a0cfeed8 
    instance_type               = "t2.micro"
    iam_instance_profile {
        name = "tf_iprofile_lt"
    }

    user_data = "${base64encode(data.template_file.userdata_lt.rendered)}"

    //instance_initiated_shutdown_behavior    = "terminate"

    vpc_security_group_ids      = [aws_security_group.ec2instances_sg.id] 

    tag_specifications {
        resource_type           = "instance"

        tags = {
            name                : "GoWeb_Cluster"
        }
    }

}

data "template_file" "userdata_lt" {
    template = <<EOF
        #!bin/bash
        sudo echo ECS_CLUSTER=tf_ecs_cluster_goweb >> /etc/ecs/ecs.config
    EOF
}

########################### ASG CONFIGURATION DEFINITION ##################################################
resource "aws_autoscaling_group" "tf_asg_example" {
    depends_on = [
        module.vpc, module.alb
    ]
    
    desired_capacity            = 1
    max_size                    = 3
    min_size                    = 1
    health_check_type           = "ELB"
    health_check_grace_period   = 3000
    vpc_zone_identifier         = module.vpc.private_subnets
    target_group_arns           = module.alb.target_group_arns
    protect_from_scale_in       = true 

    launch_template {
        id                      = aws_launch_template.tf_ec2template.id
        version                 = "$Latest"
    }

    tag {
    key                         = "AmazonECSManaged"
    value                       = "EC2"
    propagate_at_launch         = true
    }
}

#################### ECS CLUSTER AND CAPACITY PROVIDER DEFINITION´S #######################################

resource "aws_ecs_cluster" "tf_ecs_cluster" {
    name                                   = "tf_ecs_cluster_goweb"
    capacity_providers                     = [aws_ecs_capacity_provider.tf_ecs_capacity_provider.name]

    configuration {
        execute_command_configuration{
            logging     = "OVERRIDE"

            log_configuration {
                cloud_watch_encryption_enabled = true
                cloud_watch_log_group_name     = aws_cloudwatch_log_group.tf_cw_log_group.name
            }
        }
    }

    depends_on = [
        aws_ecs_capacity_provider.tf_ecs_capacity_provider
    ] 
}

resource "aws_ecs_capacity_provider" "tf_ecs_capacity_provider" {
    name                                   = "tf_ecs_capacity_provider"
    depends_on = [
        aws_autoscaling_group.tf_asg_example
    ]

    auto_scaling_group_provider {
        auto_scaling_group_arn             = aws_autoscaling_group.tf_asg_example.arn
        managed_termination_protection     = "ENABLED"


        managed_scaling {
            status                         = "ENABLED"
            maximum_scaling_step_size      = 100
            minimum_scaling_step_size      = 1
            target_capacity                = 2 
        } 
    }
}

#################### CLOUDWATCH LOG GROUP DEFINITION´S #######################################
resource "aws_cloudwatch_log_group" "tf_cw_log_group" {
    name                                   = "goweb_logs"

    tags                                   = {
        functionality      : "logs"
    }
}