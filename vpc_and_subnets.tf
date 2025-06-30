Given a vpc cidr Given a list of subnet cidrs create the vpc and subnets in different availability zones without explicitly specifying the availability zones.
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name = "Main VPC"
  }
}
resource "aws_subnet" "subnets" {
  count = length(var.subnet_cidrs)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.subnet_cidrs[count.index]
  availability_zone = element(data.aws_availability_zones.available.names, count.index % length(data.aws_availability_zones.available.names))

  tags = {
    Name = "Subnet ${count.index + 1}"
  }
}
data "aws_availability_zones" "available" {
  state = "available"
}
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}
variable "subnet_cidrs" {
  description = "List of CIDR blocks for the subnets"
  type        = list(string)
}
variable "region" {
  description = "AWS region to deploy the VPC and subnets"
  type        = string
  default     = "us-east-1"
}
provider "aws" {
  region = var.region
}

output "vpc_id" {
  description = "ID of the created VPC"
  value       = aws_vpc.main.id
}
output "subnet_ids" {
  description = "List of IDs of the created subnets"
  value       = aws_subnet.subnets[*].id
}
output "subnet_cidrs" {
  description = "List of CIDR blocks of the created subnets"
  value       = aws_subnet.subnets[*].cidr_block
}
output "availability_zones" {
  description = "List of availability zones used for the subnets"
  value       = data.aws_availability_zones.available.names
}
output "vpc_cidr" {
  description = "CIDR block of the created VPC"
  value       = aws_vpc.main.cidr_block
}
output "region" {
  description = "AWS region where the VPC and subnets are created"
  value       = var.region
}
output "aws_provider_version" {
  description = "Version of the AWS provider used"
  value       = provider.aws.version
}
output "terraform_version" {
  description = "Version of Terraform used"
  value       = terraform.version
}
