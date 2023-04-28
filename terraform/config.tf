terraform {
    required_version = ">= 0.12"
    backend "s3" {
     bucket = "terraform-react-deploy-storage"
     key = "terraform-react-deploy-storage/state.tfstate"
     region = "us-east-1"
    }
 }