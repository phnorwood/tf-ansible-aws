terraform {
  required_version = ">= 1.6"
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

# -----------------------------------------------------------------
# AMI: latest Amazon Linux 2023 (arm64 on t4g, x86_64 on t3)
# -----------------------------------------------------------------
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# -----------------------------------------------------------------
# Key pair
# -----------------------------------------------------------------
resource "aws_key_pair" "this" {
  key_name   = var.key_name
  public_key = var.ec2_public_key
}

# -----------------------------------------------------------------
# Security group — SSH open to the world
# -----------------------------------------------------------------
resource "aws_security_group" "ssh" {
  name        = "tf-ansible-ssh"
  description = "Allow SSH from anywhere"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    description      = "All outbound"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "tf-ansible-ssh"
  }
}

# -----------------------------------------------------------------
# EC2 instance — t3.micro (free-tier eligible)
# -----------------------------------------------------------------
resource "aws_instance" "this" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = "t3.micro"
  key_name                    = aws_key_pair.this.key_name
  vpc_security_group_ids      = [aws_security_group.ssh.id]
  associate_public_ip_address = true

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 8
    delete_on_termination = true
  }

  tags = {
    Name = "tf-ansible-minimal"
  }
}

# -----------------------------------------------------------------
# Generate Ansible inventory so `ansible-playbook` works immediately
# -----------------------------------------------------------------
resource "local_file" "ansible_inventory" {
  filename        = "${path.module}/../ansible/inventory/hosts.ini"
  file_permission = "0644"
  content         = <<-INI
    [managed]
    ${aws_instance.this.public_ip} ansible_user=ec2-user ansible_ssh_private_key_file=${var.ansible_private_key_path} ansible_ssh_common_args='-o StrictHostKeyChecking=no'

    [managed:vars]
    managed_user=${var.managed_user}
    managed_user_public_key=${jsonencode(var.managed_user_public_key)}
  INI
}
