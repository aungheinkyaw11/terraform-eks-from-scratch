# EKS with Terraform

This project deploys an Amazon EKS cluster on AWS using Terraform.

## What it creates

- VPC
- 3 public subnets
- 3 private subnets
- Internet Gateway
- NAT Gateway
- Route tables and associations
- IAM roles for EKS cluster and worker nodes
- EKS cluster
- EKS managed node group
- EKS add-ons:
  - VPC CNI
  - CoreDNS
  - kube-proxy
  - Metrics Server

## Notes

- The **EKS API endpoint is public**
- The **worker nodes are in private subnets**
- Private nodes use the **NAT Gateway** for outbound internet access
- Authentication mode: **API_AND_CONFIG_MAP**