provider "aws" {
  region = "ap-northeast-2"  
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.eks-test.endpoint
  token                  = data.aws_eks_cluster_auth.eks-test-auth.token
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks-test.certificate_authority[0].data)
#     exec {
#     api_version = "client.authentication.k8s.io/v1alpha1"
#     command     = "aws"
#     args        = ["eks", "get-token", "--cluster-name", data.aws_eks_cluster.eks-test.name]
#   }

}

provider "null" {}