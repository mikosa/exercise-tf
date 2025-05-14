module "network" {
  source            = "./modules/network"
  vpc_id            = var.vpc_id
  public_subnet_ids = var.public_subnet_ids
}

module "security" {
  source = "./modules/security"
  vpc_id = module.network.vpc_id
}

module "ec2_service" {
  source            = "./modules/ec2_service"
  name              = "nginx-web"
  vpc_id            = module.network.vpc_id
  public_subnet_ids = module.network.public_subnet_ids
  alb_sg_id         = module.security.alb_sg_id
  instance_sg_id    = module.security.instance_sg_id
  min_size          = 1
  max_size          = 3
  instance_type     = var.instance_type
  ami_id            = var.ami_id
}
