# infrastructure/aws/terraform/environments/dev/terraform.tfvars

region = "us-east-1"
vpc_cidr = "10.0.0.0/16"
public_subnet_1a_cidr = "10.0.1.0/24"
public_subnet_1b_cidr = "10.0.2.0/24"
private_subnet_1a_cidr = "10.0.10.0/24"
private_subnet_1b_cidr = "10.0.11.0/24"