###########################################################################################################
############# THIS SCRIPT BUILD TASK DEFINITION AND TASK TO DEPLOY A CONTAINER IMAGE ######################
###########################################################################################################


######################################### TASK DEFINITION SET UP ##########################################
resource "aws_ecs_task_definition" "tf_task_definition" {
    family                   = "service"
    network_mode             = "host"
    execution_role_arn       = aws_iam_role.tf_ecs_role.arn

    container_definitions = jsonencode([
        {
            name            = "goweb"
            image           = "002580115597.dkr.ecr.us-west-2.amazonaws.com/tf_ecr_dockers:latest"
            cpu             = 256
            memory          = 512
            essential       = true
            portMappings    = [
                {
                    containerPort = 9990
                    hostPort      = 9990
                    protocol      = "tcp"
                }
            ]
        }
    ])
}

####################################### SERVICE DEFINITION ##############################################
resource "aws_ecs_service" "tf_goweb" {
    name                = "goweb"
    cluster             = aws_ecs_cluster.tf_ecs_cluster.id
    task_definition     = aws_ecs_task_definition.tf_task_definition.arn
    scheduling_strategy = "DAEMON"
    launch_type         = "EC2"
    depends_on          = [
        aws_autoscaling_group.tf_asg_example
    ]

//    execution_role_arn  = ""

    load_balancer {
            target_group_arn  = module.alb.target_group_arns[0]
            container_name    = "goweb"
            container_port    = 9990 
    }

}
