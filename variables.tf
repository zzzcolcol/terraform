variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "eks-test"  # 기본값으로 클러스터 이름 설정
}




variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/20"  # 기본 값으로 설정된 CIDR 블록
}

variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames in the VPC"
  type        = bool
  default     = true
}

variable "enable_dns_support" {
  description = "Enable DNS support in the VPC"
  type        = bool
  default     = true
}

variable "vpc_name" {
  description = "The name of the VPC"
  type        = string
  default     = "eks-test"
}

variable "vpc_env" {
  description = "Environment tag for the VPC"
  type        = string
  default     = "dev"
}


variable "alb_chart" {
  type        = map(string)
  description = "AWS Load Balancer Controller chart"
  default = {
    name       = "aws-load-balancer-controller"
    namespace  = "kube-system"
    repository = "https://aws.github.io/eks-charts"
    chart      = "aws-load-balancer-controller"
    version    = "1.5.5"
  }
}

variable "eks_security_group_id" {
  description = "The security group ID for the EKS cluster"
  type        = string
  default = "sg-019e59011f1fc8ce5"
}