################################################################################
# VPC
################################################################################


resource "aws_vpc" "eks-test" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support

  tags = {
    Name = var.vpc_name
    Env  = var.vpc_env
  }
}


resource "aws_internet_gateway" "eks-test-igw" {
  vpc_id = aws_vpc.eks-test.id
}

resource "aws_vpc_dhcp_options" "eks-test-dhcp" {
  domain_name = "ap-northeast-2.compute.internal"
  domain_name_servers = ["AmazonProvidedDNS"]

  tags = {
    Name = "eks-test-dhcp"
    Env = "dev"
  }
}


resource "aws_vpc_dhcp_options_association" "eks-test-association" {
  vpc_id =  "${aws_vpc.eks-test.id}"
  dhcp_options_id = "${aws_vpc_dhcp_options.eks-test-dhcp.id}"
}


resource "aws_subnet" "eks-test-public2a" {
  vpc_id = "${aws_vpc.eks-test.id}"
  cidr_block = "10.0.1.0/24"
  availability_zone = "ap-northeast-2a"
  map_public_ip_on_launch = true
  tags = {
    Name = "eks-test"
    Env = "dev"
    "kubernetes.io/role/elb"  = "1"
  }
}

resource "aws_subnet" "eks-test-public2c" {
  vpc_id = "${aws_vpc.eks-test.id}"
  cidr_block = "10.0.3.0/24"
  availability_zone = "ap-northeast-2c"
  map_public_ip_on_launch = true
  tags = {
    Name = "eks-test"
    Env = "dev"
    "kubernetes.io/role/elb"  = "1"
  }
}

resource "aws_subnet" "eks-test-private2a" {
  vpc_id = "${aws_vpc.eks-test.id}"
  cidr_block = "10.0.4.0/24"
  availability_zone = "ap-northeast-2a"
  tags = {
    Name = "eks-test"
    Env = "dev"
    "kubernetes.io/role/internal-elb" = "1"

}
}


resource "aws_subnet" "eks-test-private2c" {
  vpc_id = "${aws_vpc.eks-test.id}"
  cidr_block = "10.0.6.0/24"
  availability_zone = "ap-northeast-2c"
  tags = {
    Name = "eks-test"
    Env = "dev"
    "kubernetes.io/role/internal-elb" = "1"
  }
}

resource "aws_eip" "nat-gw" {
  domain = "vpc"

}

resource "aws_nat_gateway" "eks-test-nat" {
  allocation_id = "${aws_eip.nat-gw.id}"
  subnet_id = "${aws_subnet.eks-test-public2a.id}"

}

resource "aws_route_table" "eks-test-public" {
  vpc_id = aws_vpc.eks-test.id

  tags = {
    Name = "eks-test-route-table"
  }
}

resource "aws_route_table" "eks-test-private" {
  vpc_id = aws_vpc.eks-test.id

  tags = {
    Name = "eks-test-route-table-private"
  }
}

resource "aws_route" "eks-test-internet_access" {
  route_table_id ="${aws_route_table.eks-test-public.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.eks-test-igw.id
}

resource "aws_route" "eks-test-nat" {
  route_table_id = "${aws_route_table.eks-test-private.id}"
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.eks-test-nat.id

  lifecycle {
    ignore_changes = [ nat_gateway_id ]
  }
}


resource "aws_route_table_association" "eks-test-subnet-assoication" {
  subnet_id = "${aws_subnet.eks-test-public2a.id}"
  route_table_id = aws_route_table.eks-test-public.id
}



resource "aws_route_table_association" "eks-test-subnet-assoication-3" {
  subnet_id = "${aws_subnet.eks-test-public2c.id}"
  route_table_id = aws_route_table.eks-test-public.id
}

resource "aws_route_table_association" "eks-test-subnet-assoication-4" {
  subnet_id = "${aws_subnet.eks-test-private2a.id}"
  route_table_id = aws_route_table.eks-test-private.id
}


resource "aws_route_table_association" "eks-test-subnet-assoication-6" {
  subnet_id = "${aws_subnet.eks-test-private2c.id}"
  route_table_id = aws_route_table.eks-test-private.id
}

# IAM Role creation

resource "aws_iam_role" "eks-test-role" {
  name = "eks-test-role"

  assume_role_policy =  <<EOF
  {
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "eks-test-role-attachment1" {
  role = aws_iam_role.eks-test-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}
resource "aws_iam_role_policy_attachment" "eks-test-role-attachment2" {
  role = aws_iam_role.eks-test-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
}

resource "aws_iam_role_policy_attachment" "eks_service_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.eks-test-role.name
}



# # Security group for EKS cluster
# resource "aws_security_group" "eks-test-cluster-sg" {
#   name        = "eks-test-cluster-sg"
#   description = "Security group for EKS cluster"
#   vpc_id      = aws_vpc.eks-test.id
# }

# Ingress rule for allowing traffic from another security group (EKS security group)
# resource "aws_security_group_rule" "eks_test_ingress_rule" {
#   type                     = "ingress"
#   from_port                = 0
#   to_port                  = 0
#   protocol                 = "-1"
#   security_group_id        = aws_security_group.eks-test-cluster-sg.id
#   source_security_group_id = var.eks_security_group_id  # EKS 클러스터 보안 그룹 ID
# }

# # Egress rule for allowing outbound traffic to node group subnets
# resource "aws_security_group_rule" "eks_test_egress_rule" {
#   type              = "egress"
#   from_port         = 0
#   to_port           = 0
#   protocol          = "-1"  # All protocols
#   security_group_id = aws_security_group.eks-test-cluster-sg.id

#   # CIDR blocks for node group subnets
#   cidr_blocks = [
#     aws_subnet.eks-test-private2a.cidr_block,  # Node group private subnet 1
#     aws_subnet.eks-test-private2c.cidr_block   # Node group private subnet 2
#   ]
# }



resource "aws_security_group" "eks-test-cluster-sg" {
  vpc_id = aws_vpc.eks-test.id

  # ingress  {
  #   from_port = 0
  #   to_port = 0
  #   protocol = "-1"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }

  ingress {
    from_port = 0 
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["59.10.176.51/32","10.0.0.0/20"]
  }

    egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] # 클러스터의 모든 아웃바운드 트래픽 허용
  }



  tags = {
    Name = "eks-test-cluster-sg"
  }
}

resource "aws_security_group" "eks_node_sg" {
  name        = "eks-node-sg"
  description = "Security group for EKS Node Group"
  vpc_id      = aws_vpc.eks-test.id

  ingress {
    from_port = 0 
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Egress rule for all traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "eks-node-sg"
  }

}

resource "aws_security_group_rule" "eks_node_ingress" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  security_group_id        = aws_security_group.eks_node_sg.id
 source_security_group_id = aws_security_group.eks-test-cluster-sg.id
}

resource "aws_security_group_rule" "eks_cluster_egress" {
  type                     = "egress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  security_group_id        = aws_security_group.eks-test-cluster-sg.id
  source_security_group_id = aws_security_group.eks_node_sg.id
}

## eks cluster 생성

resource "aws_eks_cluster" "eks-test" {
  enabled_cluster_log_types = ["api", "audit","authenticator","controllerManager","scheduler"]
  name = var.cluster_name
  role_arn = aws_iam_role.eks-test-role.arn

  version  = "1.29"

  vpc_config {
    endpoint_private_access = true
    endpoint_public_access = true
    public_access_cidrs = ["59.10.176.51/32","59.10.176.11/32"]
    subnet_ids = [aws_subnet.eks-test-public2a.id, aws_subnet.eks-test-public2c.id,aws_subnet.eks-test-private2a.id,aws_subnet.eks-test-private2c.id]
    security_group_ids = [aws_security_group.eks-test-cluster-sg.id]
  }

  access_config {
    authentication_mode =  "CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }

   kubernetes_network_config {
    service_ipv4_cidr = "10.100.0.0/20"
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks-test-role-attachment1,
    aws_iam_role_policy_attachment.eks-test-role-attachment2,
    aws_iam_role_policy_attachment.eks_service_policy_attachment,
    aws_cloudwatch_log_group.eks-logs-controlplane
  ]

}


resource "aws_iam_role_policy_attachment" "eks_node_policy" {
  role       = aws_iam_role.eks-test-node-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  role       = aws_iam_role.eks-test-node-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "eks_ec2_registry_policy" {
  role       = aws_iam_role.eks-test-node-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_policy" "aws_load_balancer_controller_policy" {
  name   = "AWSLoadBalancerControllerPolicy"
  policy = file("./AWSLoadBalancerController.json") # JSON 파일 경로
}

# Attach the AWS Load Balancer Controller Policy to eks-test-node-role
resource "aws_iam_role_policy_attachment" "eks_alb_policy_attachment" {
  role       = aws_iam_role.eks-test-node-role.name
  policy_arn = aws_iam_policy.aws_load_balancer_controller_policy.arn
}


# efs csi driver iam role creation
resource "aws_iam_role" "eks_efs_csi_role" {
  name = "EKS-efs-csi-role"
  assume_role_policy = file("./efs-csi-driver.json")
}



# IAM Role for eks cloud autoscaler 
resource "aws_iam_role" "eks-autoscaler-role" {
  name = "eks-autoscaler-role"

  assume_role_policy =  <<EOF
  {
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}



## Enableing IAM Roles for Service Accounts



resource "aws_cloudwatch_log_group" "eks-logs-controlplane" {
  name = "/aws/eks/${var.cluster_name}/cluster"
  retention_in_days = 7
}



resource "aws_iam_role" "eks-test-node-role" {
  name = "eks-test-node-role"

  assume_role_policy = <<EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Service": "ec2.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
      }
    ]
  }
EOF
}



resource "aws_eks_node_group" "eks-test-node-group" {
  cluster_name = aws_eks_cluster.eks-test.name
  node_group_name = "eks-test-nodegroup"
  node_role_arn = aws_iam_role.eks-test-node-role.arn
  subnet_ids = [
    aws_subnet.eks-test-private2a.id,
    aws_subnet.eks-test-private2c.id
  ]

  scaling_config {
    desired_size = 2
    max_size = 4
    min_size = 0
  }

  instance_types = ["t3.medium"]

  update_config {
    max_unavailable = 2
  }
    remote_access {
    ec2_ssh_key               = "test"  # 키 페어 이름
   source_security_group_ids = [aws_security_group.eks_node_sg.id]
  }

    tags = {
    "Name"  = "eks-test-node-group"
    # "kubernetes.io/cluster/${var.cluster_name}" = "owned"  # 변수로 태그 적용
    "k8s.io/cluster-autoscaler/enabled"         = "true"
  }

  depends_on = [ 
    aws_iam_role_policy_attachment.eks_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.eks_ec2_registry_policy
   ]
}


# resource "aws_iam_role" "ebs_csi_role" {
#   name = "ebs-csi-role"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [
#       {
#         Effect = "Allow",
#         Principal = {
#           Service = "eks.amazonaws.com"
#         },
#         Action = "sts:AssumeRole"
#       }
#     ]
#   })
# }

resource "aws_iam_role" "ebs_csi_role" {
  name = "ebs-csi-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Federated = "${aws_iam_openid_connect_provider.eks.arn}"
        },
        Action = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringEquals = {
            "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub" = "system:serviceaccount:kube-system:ebs-csi-controller-sa"
          }
        }
      }
    ]
  })
}




resource "aws_iam_policy" "ebs_csi_policy" {
  name = "ebs-csi-policy"
  description = "EBS CSI Driver policy for EKS"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ec2:CreateVolume",
          "ec2:AttachVolume",
          "ec2:DetachVolume",
          "ec2:DeleteVolume",
          "ec2:DescribeInstances",
          "ec2:DescribeVolumes",
          "ec2:DescribeVolumeAttribute",
          "ec2:DescribeVolumeStatus",
          "ec2:DescribeSnapshots",
          "ec2:CreateTags",
          "ec2:DeleteTags",
          "sts:AssumeRoleWithWebIdentity"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ebs_csi_attach_policy" {
  role       = aws_iam_role.ebs_csi_role.name
  policy_arn = aws_iam_policy.ebs_csi_policy.arn
}




resource "aws_eks_addon" "ebs_csi_addon" {
  cluster_name = aws_eks_cluster.eks-test.name  # EKS 클러스터 이름
  addon_name   = "aws-ebs-csi-driver"
  # resolve_conflicts = "OVERWRITE"
  
  service_account_role_arn = aws_iam_role.ebs_csi_role.arn
}
resource "aws_eks_addon" "ebs_metric_addon" {
  cluster_name = aws_eks_cluster.eks-test.name  # EKS 클러스터 이름
  addon_name   = "metrics-server"
}



data "aws_eks_cluster" "eks-test" {
  name =  aws_eks_cluster.eks-test.name
  depends_on = [aws_eks_cluster.eks-test]
}

data "aws_eks_cluster_auth" "eks-test-auth" {
  name = aws_eks_cluster.eks-test.name
}

resource "aws_eks_addon" "vpc_cni" {
  cluster_name = aws_eks_cluster.eks-test.name
  addon_name = "vpc-cni"
  # resolve_conflicts_on_create = "OVERWRITE"
}

resource "aws_eks_addon" "kube-proxy" {
  cluster_name = aws_eks_cluster.eks-test.name
  addon_name = "kube-proxy"
# resolve_conflicts_on_create  = "OVERWRITE"
}



resource "aws_eks_addon" "coredns" {
  cluster_name = aws_eks_cluster.eks-test.name
  addon_name = "coredns"
  # resolve_conflicts_on_create = "OVERWRITE"

  configuration_values = jsonencode({
    replicaCount = 2
    resources = {
      limits = {
        cpu = "100m"
        memory = "150Mi"
      }
      requests = {
        cpu = "100m"
        memory = "150Mi"
          }
        }
      })
    }





data "tls_certificate" "eks" {
  url = aws_eks_cluster.eks-test.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.eks-test.identity[0].oidc[0].issuer
}


### LB controllor

data "aws_iam_policy_document" "aws_load_balancer_controller_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:aws-load-balancer-controller"]
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.eks.arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "aws_load_balancer_controller" {
  assume_role_policy = data.aws_iam_policy_document.aws_load_balancer_controller_assume_role_policy.json
  name               = "aws-load-balancer-controller"
}

resource "aws_iam_policy" "aws_load_balancer_controller" {
  policy = file("./AWSLoadBalancerController.json")
  name   = "AWSLoadBalancerController"
}

resource "aws_iam_role_policy_attachment" "aws_load_balancer_controller_attach" {
  role       = aws_iam_role.aws_load_balancer_controller.name
  policy_arn = aws_iam_policy.aws_load_balancer_controller.arn
}

output "aws_load_balancer_controller_role_arn" {
  value = aws_iam_role.aws_load_balancer_controller.arn
}






## CA -cluster autoscaler


data "aws_iam_policy_document" "eks_cluster_autoscaler_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:cluster-autoscaler"]
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.eks.arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "eks_cluster_autoscaler" {
  assume_role_policy = data.aws_iam_policy_document.eks_cluster_autoscaler_assume_role_policy.json
  name               = "eks-cluster-autoscaler"
}

resource "aws_iam_policy" "eks_cluster_autoscaler" {
  name = "eks-cluster-autoscaler"

  policy = jsonencode({
    Statement = [{
      Action = [
                "autoscaling:DescribeAutoScalingGroups",
                "autoscaling:DescribeAutoScalingInstances",
                "autoscaling:DescribeLaunchConfigurations",
                "autoscaling:DescribeTags",
                "autoscaling:SetDesiredCapacity",
                "autoscaling:TerminateInstanceInAutoScalingGroup",
                "ec2:DescribeImages",
                "ec2:DescribeInstanceTypes",
                "ec2:DescribeLaunchTemplateVersions",
                "ec2:GetInstanceTypesFromInstanceRequirements",
                "eks:DescribeNodegroup",
                "autoscaling:SetDesiredCapacity",
                "autoscaling:TerminateInstanceInAutoScalingGroup"
            ]
      Effect   = "Allow"
      Resource = "*"
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_autoscaler_attach" {
  role       = aws_iam_role.eks_cluster_autoscaler.name
  policy_arn = aws_iam_policy.eks_cluster_autoscaler.arn
}

# resource "kubernetes_service_account" "ebs_csi_controller_sa" {
#   metadata {
#     name      = "ebs-csi-controller-sa"
#     namespace = "kube-system"
#     annotations = {
#       "eks.amazonaws.com/role-arn" = aws_iam_role.ebs_csi_role.arn
#     }
#   }
# }











output "eks_cluster_autoscaler_arn" {
  value = aws_iam_role.eks_cluster_autoscaler.arn
}







output "endpoint" {
  value = aws_eks_cluster.eks-test.endpoint
}

output "kubeconfig-certificate-authority-data" {
  value = aws_eks_cluster.eks-test.certificate_authority[0].data
}




