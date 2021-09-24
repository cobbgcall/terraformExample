#########################################################################################################
############################ Outputs configuration ######################################################
#########################################################################################################

output "vpc" {
    value = module.vpc.vpc_id
}

output "alb" {
    value = module.alb.lb_dns_name
}

output "launch_template_version" {
    value = aws_launch_template.tf_ec2template.latest_version
}

output "instance_profile_arn" {
    value = aws_iam_instance_profile.tf_iprofile_lt.arn
}