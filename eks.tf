resource "aws_eks_cluster" "eks" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = var.kubernetes_version

  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
    # authentication_mode = "API_AND_CONFIG_MAP"
    # Why:
    # Lets you use both the newer EKS access entry API and the older aws-auth ConfigMap.
    # This is the most flexible option for learning and migration.
    #
    # bootstrap_cluster_creator_admin_permissions = true
    # Why:
    # Gives the IAM identity that creates the cluster admin access initially,
    # so you do not get locked out right after creation.
  }

  vpc_config {
    subnet_ids = concat(
      aws_subnet.public[*].id,
      aws_subnet.private[*].id
    )

    endpoint_public_access  = true
    endpoint_private_access = false
    public_access_cidrs     = var.public_access_cidrs
    # endpoint_public_access = true
    # Why:
    # Lets you access the Kubernetes API endpoint from the internet,
    # for example from your laptop using kubectl.
    #
    # endpoint_private_access = false
    # Why:
    # Keeps the API only on public access for a simpler lab setup.
    # In production, many teams use both public and private, or private only.
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy
  ]
  # Why:
  # Ensures the cluster IAM permissions are attached before EKS creation starts.
}


# =========================================================
# Launch Template for EKS Worker Nodes
# =========================================================
resource "aws_launch_template" "eks_nodes" {
  name_prefix = "${var.cluster_name}-node-lt-"

  update_default_version = true
  # Why:
  # When you change the template, AWS can use the latest version more easily.

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = 20
      volume_type           = "gp3"
      delete_on_termination = true
    }
  }
  # Why:
  # Defines the root disk for each worker node.
  # gp3 is a good default and 20 GB is fine for a learning cluster.

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }
  # Why:
  # Enforces IMDSv2 for better EC2 metadata security.

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "${var.cluster_name}-worker-node"
    }
  }
  # Why:
  # Adds EC2 instance-level tags so the worker nodes are easier to identify.

  tag_specifications {
    resource_type = "volume"

    tags = {
      Name = "${var.cluster_name}-worker-volume"
    }
  }
  # Why:
  # Tags the EBS volumes attached to worker nodes too.
}

# =========================================================
# EKS Managed Node Group
# =========================================================
resource "aws_eks_node_group" "private_nodes" {
  cluster_name    = aws_eks_cluster.eks.name
  node_group_name = "${var.cluster_name}-private-nodes"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = aws_subnet.private[*].id

  scaling_config {
    desired_size = var.desired_size
    min_size     = var.min_size
    max_size     = var.max_size
  }
  # Why:
  # Controls how many worker nodes should exist.

  capacity_type  = "ON_DEMAND"
  instance_types = var.instance_types
  # Why:
  # ON_DEMAND is simpler and more stable for learning.
  # instance_types lets you choose the EC2 size, such as t3.medium.

  launch_template {
    id      = aws_launch_template.eks_nodes.id
    version = "$Latest"
  }
  # Why:
  # Tells the managed node group to use your custom EC2 launch template.

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_ecr_pull_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.eks_ssm_policy
  ]
  # Why:
  # Ensures worker node IAM permissions exist before node creation.
}


resource "aws_eks_access_entry" "admin" {
  cluster_name  = aws_eks_cluster.eks.name
  principal_arn = var.admin_principal_arn
  type          = "STANDARD"

  # Why:
  # Registers your SSO-backed IAM role as a valid EKS identity.
}

resource "aws_eks_access_policy_association" "admin" {
  cluster_name  = aws_eks_cluster.eks.name
  principal_arn = var.admin_principal_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }

  # Why:
  # Grants cluster-admin style permissions across the whole cluster.
}

# =========================================================
# EKS Add-ons
# =========================================================

resource "aws_eks_addon" "vpc_cni" {
  cluster_name                = aws_eks_cluster.eks.name
  addon_name                  = "vpc-cni"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  # Why:
  # vpc-cni is the networking plugin for EKS.
  # It allows pods to get IP addresses from the VPC.
}

resource "aws_eks_addon" "coredns" {
  cluster_name                = aws_eks_cluster.eks.name
  addon_name                  = "coredns"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [
    aws_eks_node_group.private_nodes
  ]

  # Why:
  # CoreDNS provides DNS inside Kubernetes.
  # Pods use it to resolve service names like my-service.default.svc.cluster.local.
  #
  # depends_on node group:
  # CoreDNS pods need worker nodes to run on.
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name                = aws_eks_cluster.eks.name
  addon_name                  = "kube-proxy"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  # Why:
  # kube-proxy handles Kubernetes service networking on each node.
}

resource "aws_eks_addon" "metrics_server" {
  cluster_name                = aws_eks_cluster.eks.name
  addon_name                  = "metrics-server"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [
    aws_eks_node_group.private_nodes
  ]

  # Why:
  # metrics-server collects CPU and memory usage from nodes and pods.
  # It is needed for commands like kubectl top nodes / kubectl top pods
  # and for autoscaling features like HPA.
}