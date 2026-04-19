aws_region         = "ap-south-1"
cluster_name       = "ahk-eks-cluster-terraform"
kubernetes_version = "1.31"

vpc_cidr = "10.0.0.0/16"

public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]

instance_types = ["t3.medium"]

desired_size = 3
min_size     = 1
max_size     = 3

admin_principal_arn = "arn:aws:iam::788279898314:role/aws-reserved/sso.amazonaws.com/AWSReservedSSO_AdministratorAccess_17c426ac93b20db7"