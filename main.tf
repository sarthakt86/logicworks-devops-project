# Provider for Region 1
provider "aws" {
  alias  = "region1"
  region = "us-east-1"
}

# Provider for Region 2
provider "aws" {
  alias  = "region2"
  region = "us-west-2"
}

# VPC in Region 1
resource "aws_vpc" "vpc_r1" {
  provider   = aws.region1
  cidr_block = "10.0.0.0/16"
  tags = { Name = "Logicworks-VPC-East" }
}

# VPC in Region 2
resource "aws_vpc" "vpc_r2" {
  provider   = aws.region2
  cidr_block = "10.1.0.0/16"
  tags = { Name = "Logicworks-VPC-West" }
}

# Subnets in Region 1 (Mumbai/Virginia - East)
resource "aws_subnet" "pub_sub_r1" {
  provider   = aws.region1
  vpc_id     = aws_vpc.vpc_r1.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true
  tags = { Name = "Public-Subnet-R1" }
}

# Subnets in Region 2 (Singapore/Oregon - West)
resource "aws_subnet" "pub_sub_r2" {
  provider   = aws.region2
  vpc_id     = aws_vpc.vpc_r2.id
  cidr_block = "10.1.1.0/24"
  map_public_ip_on_launch = true
  tags = { Name = "Public-Subnet-R2" }
}

# Internet Gateway for Region 1
resource "aws_internet_gateway" "igw_r1" {
  provider = aws.region1
  vpc_id   = aws_vpc.vpc_r1.id
}

# Internet Gateway for Region 2
resource "aws_internet_gateway" "igw_r2" {
  provider = aws.region2
  vpc_id   = aws_vpc.vpc_r2.id
}

# Docker Repository in Region 1
resource "aws_ecr_repository" "app_repo_r1" {
  provider = aws.region1
  name     = "logicworks-app-repo"
  force_delete = true # Taaki project khatam hone par asani se delete ho sake
}

# Docker Repository in Region 2 (Replication requirement ke liye)
resource "aws_ecr_repository" "app_repo_r2" {
  provider = aws.region2
  name     = "logicworks-app-repo-replica"
  force_delete = true
}

# IAM Role for CodeBuild (Permissions dena zaroori hai)
resource "aws_iam_role" "codebuild_role" {
  name = "codebuild-logicworks-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = { Service = "codebuild.amazonaws.com" }
      },
    ]
  })
}

# CodeBuild Project (Jo Docker build karega AWS par)
resource "aws_codebuild_project" "app_build" {
  provider      = aws.region1
  name          = "Logicworks-Build"
  service_role  = aws_iam_role.codebuild_role.arn

  artifacts { type = "NO_ARTIFACTS" }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:4.0"
    type                        = "LINUX_CONTAINER"
    privileged_mode             = true # Docker build ke liye zaroori hai
  }

  source {
    type     = "GITHUB"
    location = "https://github.com/sarthakt86/logicworks-devops-project.git"
  }
}

# Policy for CodeBuild permissions
resource "aws_iam_role_policy" "codebuild_policy" {
  name = "logicworks-codebuild-policy"
  role = aws_iam_role.codebuild_role.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}