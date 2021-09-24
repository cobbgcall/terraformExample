#########################################################################################################
################# This script create storage´s resource #################################################
#########################################################################################################

module "s3_bucket" {
    source                                  = "terraform-aws-modules/s3-bucket/aws"

    bucket                                  = "aws-balancer-002580115597"
    acl                                     = "log-delivery-write"

    attach_elb_log_delivery_policy          = true
}