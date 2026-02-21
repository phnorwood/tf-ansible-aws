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

variable "managed_user" {
  description = "Username to create on the instance for day-to-day SSH access"
  type        = string
  default     = "deploy"
}

variable "managed_user_public_key" {
  description = "Your personal public SSH key for the managed user (paste contents of your .pub file). This is how you SSH in after Ansible runs."
  type        = string
}
