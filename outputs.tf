output "vpc_id" {
  value = aws_vpc.eks_vpc.id
  # Useful for troubleshooting and future integrations
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
  # Shows all public subnet IDs
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
  # Shows all private subnet IDs
}

output "eks_cluster_name" {
  value = aws_eks_cluster.eks.name
  # Needed for aws eks update-kubeconfig
}

output "eks_cluster_endpoint" {
  value = aws_eks_cluster.eks.endpoint
  # API endpoint of the Kubernetes control plane
}

output "eks_cluster_ca" {
  value     = aws_eks_cluster.eks.certificate_authority[0].data
  sensitive = true
  # Certificate authority data for secure kubectl communication
}