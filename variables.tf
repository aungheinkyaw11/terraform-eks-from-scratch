variable "aws_region" {
  type    = string
  default = "ap-south-1"
  # AWS region where EKS and networking resources will be created
}

variable "cluster_name" {
  type    = string
  default = "ahk-eks-cluster"
  # Name of the EKS cluster
}

variable "kubernetes_version" {
  type    = string
  default = "1.31"
  # Kubernetes version for the EKS control plane
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
  # Main CIDR block for the VPC
}

variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "private_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
  # We use 3 private subnets for worker nodes
}

variable "instance_types" {
  type    = list(string)
  default = ["t3.medium"]
  # EC2 instance type for worker nodes
}

variable "desired_size" {
  type    = number
  default = 2
  # Desired number of worker nodes
}

variable "min_size" {
  type    = number
  default = 1
  # Minimum worker nodes
}

variable "max_size" {
  type    = number
  default = 3
  # Maximum worker nodes
}

variable "admin_principal_arn" {
  type = string
  # Example:
  # arn:aws:iam::123456789012:user/your-user
  #
  # Why:
  # This is the IAM user or role that should get cluster access via EKS access entries.
}

variable "public_access_cidrs" {
  type        = list(string)
  default     = ["0.0.0.0/0"]
  description = "CIDR blocks allowed to access the EKS public API endpoint"

  # Why:
  # This controls which IP ranges can reach the public Kubernetes API.
  # For testing, 0.0.0.0/0 allows everyone.
  # For better security, replace it with your public IP like ["1.2.3.4/32"].
}