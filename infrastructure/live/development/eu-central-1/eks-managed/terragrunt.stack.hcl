locals {
  env             = "development"
  region          = "eu-central-1"
  project         = "eks-runner"
  project_version = "1.0.0"

  development_account_id    = "567749996660"
  development_account_email = "gergodevops@gmail.com"
  organization_id           = "o-0000000000"
  organization_root_id      = "r-0000"
  
  
  tags = {
    Project     = local.project
    Environment = local.env
    Maintainer   = "Terragrunt"
  }
}

unit "vpc" {
  source = "../../../../../units/vpc"
  path   = "vpc"

  values = {
    name = "${local.project}-${local.env}-vpc"
    cidr = "10.0.0.0/16"

    azs             = ["${local.region}a", "${local.region}b", "${local.region}c"]
    private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
    public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

    enable_nat_gateway     = true
    single_nat_gateway     = true
    one_nat_gateway_per_az = false

    enable_dns_hostnames = true
    enable_dns_support   = true

    enable_flow_log                      = false
    create_flow_log_cloudwatch_iam_role  = false
    create_flow_log_cloudwatch_log_group = false

    
    cluster_name = "${local.project}-${local.env}-cluster"
    
    
    tags = {
      Name        = "${local.project}-${local.env}-vpc"
      Environment = "development"
      Project     = "${local.project}"
      ManagedBy   = "Terragrunt"
    }
  }
}




unit "kms" {
  source = "../../../../../units/kms"
  path   = "kms"

  values = {
    description = "KMS key for EKS cluster encryption"
    aliases     = ["alias/eks-cluster-encryption"]

    key_administrators = [
      "arn:aws:iam::${local.development_account_id}:root",
      "arn:aws:iam::${local.development_account_id}:role/terragrunt-execution-role"
    ]

    deletion_window_in_days = 7

    tags = {
      Name        = "eks-cluster-kms-key"
      Environment = "development"
      Purpose     = "EKS-Encryption"
    }
  }
}

unit "eks" {
  source = "../../../../../units/eks"
  path   = "eks"

  values = {
    vpc_path = "../vpc"
    kms_path = "../kms"

    cluster_name    = "${local.project}-cluster"
    cluster_version = "1.31"

    enable_auto_mode              = false
    bootstrap_self_managed_addons = true

    eks_managed_node_groups = {
      default = {
        min_size       = 1
        max_size       = 3
        desired_size   = 2
        instance_types = ["t3.medium"]
        ami_type       = "AL2_x86_64"
        capacity_type  = "ON_DEMAND"

        labels = {
          Environment = "development"
          NodeGroup   = "default"
        }

        taints = []
        
        block_device_mappings = {
          xvda = {
            device_name = "/dev/xvda"
            ebs = {
              volume_size           = 20
              volume_type           = "gp3"
              encrypted             = true
              delete_on_termination = true
            }
          }
        }

        update_config = {
          max_unavailable_percentage = 25
        }

        metadata_options = {
          http_endpoint               = "enabled"
          http_tokens                 = "required"
          http_put_response_hop_limit = 2
          instance_metadata_tags      = "disabled"
        }
      }
    }

    cluster_addons = {
      coredns = {
        version = "v1.11.1-eksbuild.4"
      }
      kube-proxy = {
        version = "v1.31.0-eksbuild.3"
      }
      vpc-cni = {
        version = "v1.18.1-eksbuild.3"
      }
    }

    cluster_endpoint_public_access       = true
    cluster_endpoint_private_access      = true
    cluster_endpoint_public_access_cidrs = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]

    authentication_mode = "API_AND_CONFIG_MAP"

    access_entries = {
      admin = {
        principal_arn     = "arn:aws:iam::${local.development_account_id}:role/terragrunt-execution-role"
        kubernetes_groups = ["system:masters"]
        policy_associations = {
          admin = {
            policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
            access_scope = {
              type = "cluster"
            }
          }
        }
      }
    }

    enable_irsa = true

    enable_kms_encryption = true

    cluster_enabled_log_types              = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
    cloudwatch_log_group_retention_in_days = 30
    create_cloudwatch_log_group            = true

    cluster_security_group_additional_rules = {
      ingress_nodes_443 = {
        description                = "Node groups to cluster API"
        protocol                   = "tcp"
        from_port                  = 443
        to_port                    = 443
        type                       = "ingress"
        source_node_security_group = true
      }
    }
    
    node_security_group_additional_rules = {
      ingress_self_all = {
        description = "Node to node all ports/protocols"
        protocol    = "-1"
        from_port   = 0
        to_port     = 0
        type        = "ingress"
        self        = true
      }
      
      egress_all = {
        description      = "Node all egress"
        protocol         = "-1"
        from_port        = 0
        to_port          = 0
        type             = "egress"
        cidr_blocks      = ["0.0.0.0/0"]
        ipv6_cidr_blocks = ["::/0"]
      }
    }

    tags = {
      Name        = "${local.project}-cluster"
      Environment = "development"
      ManagedBy   = "Terragrunt"
      EKSMode     = "Managed"
    }
  }
}

unit "ebs_csi_driver" {
  source = "../../../../../units/ebs-csi-driver"
  path   = "ebs-csi-driver"

  values = {
    eks_path = "../eks"
    kms_path = "../kms"

    role_name                  = "ebs-csi-driver-role"
    namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]

    enable_kms_encryption = true

    tags = {
      Name        = "ebs-csi-driver-role"
      Environment = "development"
      Purpose     = "EBS-CSI-Driver"
    }
  }
}

unit "aws_load_balancer_controller" {
  source = "../../../../../units/aws-lbc"
  path   = "aws-load-balancer-controller"

  values = {
    eks_path = "../eks"

    helm_chart_name         = "aws-load-balancer-controller"
    helm_chart_release_name = "aws-load-balancer-controller"
    helm_chart_repo         = "https://aws.github.io/eks-charts"
    helm_chart_version      = "1.8.4"

    namespace            = "kube-system"
    service_account_name = "aws-load-balancer-controller"

    irsa_role_name_prefix = "aws-load-balancer-controller"

    # need vpc id?
    helm_chart_values = [
      <<-EOT
      clusterName: ${local.project}-cluster
      serviceAccount:
        create: true
        name: aws-load-balancer-controller
      region: ${local.region}
      EOT
    ]

    tags = {
      Name        = "aws-load-balancer-controller"
      Environment = "development"
      Purpose     = "Load-Balancer-Controller"
    }
  }
}

unit "additional_iam_roles" {
  source = "../../../../../units/iam-role"
  path   = "additional-iam-roles"

  values = {
    eks_path = "../eks"

    role_name = "external-dns-role"

    namespace_service_accounts = ["kube-system:external-dns"]

    attach_external_dns_policy = true

    role_policy_arns = {}

    tags = {
      Name        = "external-dns-role"
      Environment = "development"
      Purpose     = "External-DNS"
    }
  }
}

