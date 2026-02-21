variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "key_name" {
  description = "Name for the AWS key pair resource"
  type        = string
  default     = "tf-ansible-key"
}

variable "ec2_public_key" {
  description = "Public SSH key used for initial EC2 access (ec2-user). Paste the contents of your .pub file."
  type        = string
}

variable "managed_user" {
  description = "Username to create on the instance for day-to-day SSH access"
  type        = string
  default     = "deploy"
}

variable "managed_user_public_key" {
  description = "Public SSH key for the managed user. Can be the same as ec2_public_key."
  type        = string
}

variable "ansible_private_key_path" {
  description = "Local path to the private key that corresponds to ec2_public_key (used by Ansible to connect)"
  type        = string
}
