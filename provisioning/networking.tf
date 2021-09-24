#########################################################################################################
################# This script create a network for deployment ###########################################
#########################################################################################################

module "vpc" {
    source              = "terraform-aws-modules/vpc/aws"
    name                = "networking"
    cidr                = var.cidrblock

    azs                 = var.azs
    public_subnets      = var.public_subnets
    private_subnets     = var.private_subnets

    enable_nat_gateway  = var.azs_nat_gateways
    enable_vpn_gateway  = var.vpn_gateway
    single_nat_gateway  = false

    enable_dns_hostnames = true
    enable_dns_support   = true

    tags = {
        functionality   : "networking"
    }
}