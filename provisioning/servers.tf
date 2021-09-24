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
}

########################## EC2 Instances Security Group #################################################
resource "aws_security_group" "ec2instances_sg" {
    name                        = "SG-ec2"
    description                 = "Security Group for EC2 Instances"
    vpc_id                      = module.vpc.vpc_id

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
            backend_port        = 80
            target_type         = "instance"
            targets = []
        }
    ]

    http_tcp_listeners = [
        {
            port                = 80
            protocol            = "HTTP"
            targetr_group_index = 0
        }
    ]

    tags = {
        functionality      : "application"
    }
}

########################### Launch Templeate definition ##################################################
resource "aws_launch_template" "tf_ec2template" {
    name                        = "tf_ec2lachuntemplate"

    block_device_mappings {
        device_name             = "/dev/sda1"

    ebs {
        volume_size             = 20
        volume_type             = "gp3"
        encrypted               = true
    }
    }

    image_id                    = "ami-a0cfeed8"
    instance_type               = "t2.micro"
    iam_instance_profile {
        name = "tf_iprofile_lt"
    }

    instance_initiated_shutdown_behavior    = "terminate"

    vpc_security_group_ids      = [aws_security_group.ec2instances_sg.id] 

    tag_specifications {
        resource_type           = "instance"

        tags = {
            name                : "app_server"
        }
    }

}

########################### ASG Configuration definition ##################################################
resource "aws_autoscaling_group" "tf_asg_example" {
    depends_on = [
        module.vpc
    ]
    
    desired_capacity            = 1
    max_size                    = 2
    min_size                    = 1
    health_check_type           = "ELB"
    health_check_grace_period   = 300
    vpc_zone_identifier         = module.vpc.private_subnets
    target_group_arns           = module.alb.target_group_arns

    launch_template {
        id                      = aws_launch_template.tf_ec2template.id
        version                 = "$Latest"
    }
}