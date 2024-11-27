# infrastructure/aws/terraform/environments/staging/terraform.tfvars

region                = "us-east-1"
vpc_cidr              = "10.1.0.0/16"
public_subnet_1a_cidr = "10.1.1.0/24"
public_subnet_1b_cidr = "10.1.2.0/24"
private_subnet_1a_cidr = "10.1.10.0/24"
private_subnet_1b_cidr = "10.1.11.0/24"
notebook_instance_type = "ml.t3.xlarge"
notebook_volume_size   = 100
lambda_source_path     = "../../../lambda"
prod_account_id        = "YOUR-PROD-ACCOUNT-ID"