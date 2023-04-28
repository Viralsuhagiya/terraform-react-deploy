provider "aws" {
  region = var.region
}

module "loggroup_module" {
    source = "./modules/loggroup"
    app_name = var.app_name
    env = var.env
}

module "ecr_module" {
    source = "./modules/ecr"
    app_name = var.app_name
    env = var.env
}

module "iam_module" {
    source = "./modules/iam"
    app_name = var.app_name
    env = var.env
}

module "vpc_module" {
    source = "./modules/vpc"
    app_name = var.app_name
    env = var.env
}

module "security_module" {
    source = "./modules/security"
    app_name = var.app_name
    env = var.env
    vpc_id = module.vpc_module.vpc.id
}

module "loadbalancer_module" {
    source = "./modules/loadbalancer"
    app_name = var.app_name
    env = var.env
    security_id = module.security_module.security.id
    subnet1 = module.vpc_module.subnet1.id
    subnet2 = module.vpc_module.subnet2.id
    vpc_id = module.vpc_module.vpc.id
}

module "ecs_module" {
    source = "./modules/ecs"
    app_name = var.app_name
    env = var.env
    region = var.region
    image =  module.ecr_module.ecr.repository_url
    loggroup = module.loggroup_module.loggroup.name
    execution_role_arn = module.iam_module.iam_role.arn
    security_id = module.security_module.security.id
    subnet1 = module.vpc_module.subnet1.id
    subnet2 = module.vpc_module.subnet2.id
    target_group_arn = module.loadbalancer_module.target_group.arn
}