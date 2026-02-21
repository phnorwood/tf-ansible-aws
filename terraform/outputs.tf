output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.this.id
}

output "public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.this.public_ip
}

output "public_dns" {
  description = "Public DNS of the EC2 instance"
  value       = aws_instance.this.public_dns
}

output "ami_id" {
  description = "AMI used for the instance"
  value       = data.aws_ami.al2023.id
}

output "managed_user" {
  description = "Username created on the instance by Ansible"
  value       = var.managed_user
}

output "ansible_private_key_path" {
  description = "Private key path used by Ansible (mirrors the input variable)"
  value       = var.ansible_private_key_path
}

output "ssh_command_ec2_user" {
  description = "SSH command to connect as ec2-user (before Ansible runs)"
  value       = "ssh -i ${var.ansible_private_key_path} ec2-user@${aws_instance.this.public_ip}"
}

output "ssh_command_managed_user" {
  description = "SSH command to connect as the managed user (after Ansible runs)"
  value       = "ssh -i ${var.ansible_private_key_path} ${var.managed_user}@${aws_instance.this.public_ip}"
}
