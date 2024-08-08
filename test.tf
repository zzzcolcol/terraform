resource "aws_vpc" "eks-test" {
  cidr_block = "10.0.0.0/20"

  tags = {
    Name = "eks-test"
    Env  = "dev"
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
  tags = {
    Name = "eks-test"
    Env = "dev"
  }
}

resource "aws_subnet" "eks-test-public2b" {
  vpc_id = "${aws_vpc.eks-test.id}"
  cidr_block = "10.0.2.0/24"
  availability_zone = "ap-northeast-2b"
  tags = {
    Name = "eks-test"
    Env = "dev"
  }
}

resource "aws_subnet" "eks-test-public2c" {
  vpc_id = "${aws_vpc.eks-test.id}"
  cidr_block = "10.0.3.0/24"
  availability_zone = "ap-northeast-2c"
  tags = {
    Name = "eks-test"
    Env = "dev"
  }
}

resource "aws_subnet" "eks-test-private2a" {
  vpc_id = "${aws_vpc.eks-test.id}"
  cidr_block = "10.0.4.0/24"
  availability_zone = "ap-northeast-2a"
  tags = {
    Name = "eks-test"
    Env = "dev"
  }
}

resource "aws_subnet" "eks-test-private2b" {
  vpc_id = "${aws_vpc.eks-test.id}"
  cidr_block = "10.0.5.0/24"
  availability_zone = "ap-northeast-2b"
  tags = {
    Name = "eks-test"
    Env = "dev"
  }
}


resource "aws_subnet" "eks-test-private2c" {
  vpc_id = "${aws_vpc.eks-test.id}"
  cidr_block = "10.0.6.0/24"
  availability_zone = "ap-northeast-2c"
  tags = {
    Name = "eks-test"
    Env = "dev"
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

resource "aws_route_table_association" "eks-test-subnet-assoication-2" {
  subnet_id = "${aws_subnet.eks-test-public2b.id}"
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

resource "aws_route_table_association" "eks-test-subnet-assoication-5" {
  subnet_id = "${aws_subnet.eks-test-private2b.id}"
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

variable "cluster_name" {
  default = "eks-test"
  type = string
}

resource "aws_eks_cluster" "eks-test" {
  enabled_cluster_log_types = ["api", "audit"]
  name = var.cluster_name
  role_arn = aws_iam_role.eks-test-role.arn

  vpc_config {
    subnet_ids = [aws_subnet.eks-test-private2a.id, aws_subnet.eks-test-private2c.id]
  }

  access_config {
    authentication_mode =  "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks-test-role-attachment1,
    aws_iam_role_policy_attachment.eks-test-role-attachment2,
    aws_cloudwatch_log_group.eks-logs-controlplane
  ]

}


resource "aws_cloudwatch_log_group" "eks-logs-controlplane" {
  name = "/aws/eks/${var.cluster_name}/cluster"
  retention_in_days = 7
}



locals {
    managed_policy_arns = [
     "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
     "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
     "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  ]
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


resource "aws_iam_role_policy_attachment" "eks-node-role-attachment" {
  count      = length(local.managed_policy_arns)
  role       = aws_iam_role.eks-test-node-role.name
  policy_arn = local.managed_policy_arns[count.index]
}



resource "aws_eks_node_group" "eks-test-node-group" {
  cluster_name = aws_eks_cluster.eks-test.name
  node_group_name = "eks-test-nodegroup"
  node_role_arn = aws_iam_role.eks-test-node-role.arn
  subnet_ids = [
    aws_subnet.eks-test-private2a.id,
    aws_subnet.eks-test-private2b.id,
    aws_subnet.eks-test-private2c.id
  ]

  scaling_config {
    desired_size = 1
    max_size = 2
    min_size = 1
  }

  update_config {
    max_unavailable = 1
  }

  depends_on = [ 
    aws_iam_role_policy_attachment.eks-node-role-attachment
   ]
}


data "aws_eks_cluster" "eks-test" {
  name =  aws_eks_cluster.eks-test.name
}

data "aws_eks_cluster_auth" "eks-test-auth" {
  name = aws_eks_cluster.eks-test.name
}

resource "aws_eks_addon" "vpc_cni" {
  cluster_name = aws_eks_cluster.eks-test.name
  addon_name = "vpc-cni"
  resolve_conflicts_on_create = "OVERWRITE"
}

resource "aws_eks_addon" "coredns" {
  cluster_name = aws_eks_cluster.eks-test.name
  addon_name = "coredns"
  resolve_conflicts_on_create = "OVERWRITE"
}



data "aws_iam_role" "sso_role" {
  name = "AWSReservedSSO_AWSAdministratorAccess_20e3efd18e0823c7"
}

resource "aws_eks_access_policy_association" "eks-test-policy" {
  cluster_name = aws_eks_cluster.eks-test.name
  policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy"
  principal_arn = "arn:aws:iam::120653558546:role/AWSReservedSSO_AWSAdministratorAccess_20e3efd18e0823c7"


  access_scope {
    type = "namespace"
    namespaces = ["kube-system"]
  }
}


# resource "local_file" "kubeconfig" {
#   content = <<EOF
# apiVersion: v1
# clusters:
# - cluster:
#     server: ${data.aws_eks_cluster.eks-test.endpoint}
#     certificate-authority-data: ${data.aws_eks_cluster.eks-test.certificate_authority[0].data}
#   name: kubernetes
# contexts:
# - context:
#     cluster: kubernetes
#     user: aws
#   name: aws
# current-context: aws
# kind: Config
# preferences: {}
# users:
# - name: aws
#   user:
#     token: ${data.aws_eks_cluster_auth.eks-test-auth.token}
# EOF
#   filename = "${path.module}/kubeconfig"
# }




# resource "null_resource" "update_aws_auth" {
#   provisioner "local-exec" {
#     command = <<EOT
#     kubectl get configmap aws-auth -n kube-system -o yaml > aws-auth.yaml
#     echo "
# - userarn: arn:aws:iam::120653558546:role/AWSReservedSSO_AWSAdministratorAccess_20e3efd18e0823c7
#   username: kyeongju
#   groups:
#     - system:masters
# " >> aws-auth.yaml
#     kubectl apply -f aws-auth.yaml
#     EOT
#   }

#   depends_on = [
#     aws_iam_role.eks-test-node-role,
#     aws_iam_role_policy_attachment.eks-node-role-attachment
#   ]
# }

# resource "kubernetes_cluster_role_binding" "cluster_admin_binding" {
#   metadata {
#     name = "cluster-admin-binding"
#   }

#   role_ref {
#     api_group = "rbac.authorization.k8s.io"
#     kind      = "ClusterRole"
#     name      = "cluster-admin"
#   }

#   subject {
#     kind      = "User"
#     name      = "johndoe@example.com"
#     api_group = "rbac.authorization.k8s.io"
#   }
# }




data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"
  

  principals {
    type  = "Service"
    identifiers = ["pods.eks.amazonaws.com"]
  }

  actions = [
    "sts:AssumeRole",
    "sts:TagSession"
  ]

  }

}

resource "aws_iam_role" "pod-role" {
  name = "eks-pod-identity-pod-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "pod-role-s3" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
  role = aws_iam_role.pod-role.name
}

resource "aws_eks_pod_identity_association" "pod-role-association" {
  cluster_name = aws_eks_cluster.eks-test.name
  namespace = "kube-system"
  service_account = "kube-system-sa"
  role_arn = aws_iam_role.pod-role.arn
}

output "endpoint" {
  value = aws_eks_cluster.eks-test.endpoint
}

output "kubeconfig-certificate-authority-data" {
  value = aws_eks_cluster.eks-test.certificate_authority[0].data
}
