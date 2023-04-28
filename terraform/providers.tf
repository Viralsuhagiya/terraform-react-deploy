terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "4.64.0"
    }
    docker = {
      source = "kreuzwerker/docker"
    }
  }
  required_version = ">= 1.2.0"
}