terraform {
  required_version = ">= 1.3"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Security Group
resource "aws_security_group" "activegate_sg" {
  name   = "activegate-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 9999
    to_port     = 9999
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# AWS Key Pair
resource "aws_key_pair" "default" {
  key_name   = var.key_name
  public_key = file(var.public_key_path)
}

# EC2 Instance for ActiveGate
resource "aws_instance" "activegate_vm" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_security_group.activegate_sg.id]

  tags = {
    Name = "dynatrace-activegate"
  }
}

output "activegate_public_ip" {
  value = aws_instance.activegate_vm.public_ip
}

output "activegate_private_ip" {
  value = aws_instance.activegate_vm.private_ip
}

output "ssh_user" {
  value = "ec2-user"
}
