# infrastructure/aws/terraform/environments/prod/terraform.tfvars

region                = "us-east-1"
vpc_cidr              = "10.2.0.0/16"
public_subnet_1a_cidr = "10.2.1.0/24"
public_subnet_1b_cidr = "10.2.2.0/24"
private_subnet_1a_cidr = "10.2.10.0/24"
private_subnet_1b_cidr = "10.2.11.0/24"
notebook_instance_type = "ml.t3.2xlarge"
notebook_volume_size   = 200
lambda_source_path     = "../../../lambda"