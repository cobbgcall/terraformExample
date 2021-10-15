######################################################################################################################
##################### This file contain the main configuration to build resources on AWS with Terraform ##############
######################################################################################################################

##################### Provider configuration has parameters to connect with AWS profile ##############################
##################### Also it has default tags for all resources #####################################################

provider "aws" {
    profile = "PERSONAL"
    region = "us-west-2"

    default_tags {
    tags = {
        environment     : var.deploy_environment
        project         : "Example_1"
        language        : "terraform"
        }
    }

}

#####################################################################################################################
####################### VARIABLES ARE AGROUPED BY FUNCTIONALITY OR RESOURCE TO BUILD ################################
#####################################################################################################################

############################################# VPC VARIABLES #########################################################

variable "deploy_environment" {
    type    = string
    default = "Dev"
}

variable "cidrblock" {
    type    = string 
}

variable "vpn_gateway" {
    type    = bool
    default = false
}

variable "azs" {
    type    = list(string)
}

variable "public_subnets" {
    type    = list(string)
}

variable "private_subnets" {
    type    = list(string)
}

variable "azs_nat_gateways" {
    type    = bool
}

variable "single_nat" {
    type    = bool 
}

############################################# SERVER VARIABLES ######################################################

variable "whitelist" {
    type    = list(string)
}

variable "internet_access" {
    type    = string     
}

variable "ipv6_cidr_ia" {
    type  = string
}

############################################# SECURITY VARIABLES ####################################################

variable "role_arns_policies" {
    type = list(string)
}

variable "role_arns_policies_ecs" {
    type = list(string)
}