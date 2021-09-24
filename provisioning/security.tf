#########################################################################################################
################### This script creates the security components requiered by the app ####################
#########################################################################################################


#################### INSTANCE PROFILE, IT WILL BE JOINED TO EC2 INSTANCES ###############################

resource "aws_iam_instance_profile" "tf_iprofile_lt" {
    name                    = "tf_iprofile_lt"
    role                    = aws_iam_role.tf_role_ec2.name

    tags = {
        functionality  : "security"
    }
}

#################### ROLE DEFINITION FOR INSTANCE PROFILE ###############################################
resource "aws_iam_role" "tf_role_ec2" {
    name                    = "tf_role_ec2"
    description             = "This role asigns SSM and CloudWatch Agent access"
    max_session_duration    = 7200
    path                    = "/"
    managed_policy_arns     = var.role_arns_policies

    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Action = "sts:AssumeRole"
                Effect = "Allow"
                Principal = {
                    Service = "ec2.amazonaws.com"
                }
            }            
        ]  
    })

    tags = {
        functionality   : "security"
    }
}