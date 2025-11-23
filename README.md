# dynatrace_ag_tf_ansible
This repo is to create the aws instance via terraform and then deploy Dnatrace activegate via ansible 

PROJECT STRUCTURE (as requested)
terraform/
├── infra/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│
└── ansible/
    ├── ansible.cfg
    ├── inventory.ini
    └── deploy_activegate.yml

=====================================================================
📁 terraform/infra/main.tf
=====================================================================
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

=====================================================================
📁 terraform/infra/variables.tf
=====================================================================
variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "key_name" {
  type = string
}

variable "public_key_path" {
  type = string
}

variable "ami_id" {
  type    = string
  default = "ami-0c02fb55956c7d316" # Amazon Linux 2
}

variable "instance_type" {
  type    = string
  default = "t3.medium"
}

variable "vpc_id" {
  type = string
}

variable "subnet_id" {
  type = string
}

=====================================================================
📁 terraform/infra/outputs.tf
=====================================================================
output "activegate_public_ip" {
  value = aws_instance.activegate_vm.public_ip
}

output "activegate_private_ip" {
  value = aws_instance.activegate_vm.private_ip
}

output "ssh_user" {
  value = "ec2-user"
}

=====================================================================
📁 terraform/ansible/ansible.cfg
=====================================================================
[defaults]
inventory = inventory.ini
host_key_checking = False
retry_files_enabled = False
private_key_file = /home/cloud_user/.ssh/test.pem
remote_user = ec2-user

=====================================================================
📁 terraform/ansible/inventory.ini
=====================================================================

After Terraform finishes, replace <EC2_PUBLIC_IP> with:

terraform output activegate_public_ip

[activegate]
dynatrace_vm ansible_host=<EC2_PUBLIC_IP>

=====================================================================
📁 terraform/ansible/deploy_activegate.yml
=====================================================================
---
- name: Install Dynatrace ActiveGate
  hosts: activegate
  become: yes

  vars:
    dynatrace_tenant: "<YOUR_TENANT_ID>.live.dynatrace.com"
    dynatrace_installer_token: "<YOUR_INSTALLER_TOKEN>"

  tasks:

    - name: Install required dependencies
      yum:
        name:
          - wget
          - unzip
        state: present

    - name: Download Dynatrace ActiveGate installer
      get_url:
        url: "https://{{ dynatrace_tenant }}/api/v1/deployment/installer/agent/unix/activegate/latest?Api-Token={{ dynatrace_installer_token }}"
        dest: /tmp/ActiveGate.sh
        mode: '0755'

    - name: Run ActiveGate installer
      shell: |
        sh /tmp/ActiveGate.sh
      args:
        chdir: /tmp

🚀 Deployment Instructions
1. Apply Terraform
cd terraform/infra
terraform init
terraform apply \
  -var "key_name=test" \
  -var "public_key_path=/home/cloud_user/.ssh/test.pub" \
  -var "vpc_id=vpc-xxxx" \
  -var "subnet_id=subnet-xxxx"


Get the IP:

terraform output activegate_public_ip


Update inventory:

cd ../ansible
nano inventory.ini

2. Run Ansible

Test SSH:

ansible -m ping activegate


Run ActiveGate install:

ansible-playbook deploy_activegate.yml
