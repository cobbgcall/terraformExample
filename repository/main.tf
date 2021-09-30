######################################################################################################################
##################### THIS FILE CONTAIN THE MAIN CONFIGURATION TO BUILD ECR REPOSITORY ##############
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

variable "deploy_environment" {
    type    = string
    default = "Dev"
}

resource "aws_ecr_repository" "tf_ecr_dockers" {
    name                    = "tf_ecr_dockers"
    image_tag_mutability    = "MUTABLE"

    image_scanning_configuration {
        scan_on_push        = false 
    }

    tags = {
        repository  : "dockers"
    }       
}