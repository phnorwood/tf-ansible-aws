# tf-ansible-aws

Minimal AWS EC2 instance deployed with Terraform and configured with Ansible.

- **Instance**: t3.micro, Amazon Linux 2023, 8 GB gp3 root volume
- **Access**: SSH from anywhere (port 22 open to `0.0.0.0/0`)
- **Auth**: SSH public-key only — passwords completely disabled
- **User**: a dedicated `deploy` user (configurable) is created; `ec2-user` is kept for emergency access

---

## Prerequisites

| Tool | Version |
|------|---------|
| Terraform | ≥ 1.6 |
| Ansible | ≥ 2.14 |
| AWS CLI | configured with credentials |

Install the required Ansible collection:

```bash
ansible-galaxy collection install -r ansible/requirements.yml
```

---

## 1 — Configure Terraform variables

```bash
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
```

Edit `terraform/terraform.tfvars` and set:

| Variable | Description |
|----------|-------------|
| `aws_region` | AWS region (default: `us-east-1`) |
| `key_name` | Name for the AWS key pair |
| `ec2_public_key` | Contents of your public key (e.g. `~/.ssh/id_ed25519.pub`) |
| `managed_user` | Username to create (default: `deploy`) |
| `managed_user_public_key` | Public key for the managed user |
| `ansible_private_key_path` | Path to the private key Ansible will use to connect |

> **Never commit `terraform.tfvars`** — it contains your public key paths and is gitignored.

---

## 2 — Deploy the infrastructure

```bash
cd terraform
terraform init
terraform apply
```

Terraform will:
1. Find the latest Amazon Linux 2023 AMI
2. Create an EC2 key pair, security group, and t3.micro instance
3. Write `ansible/inventory/hosts.ini` with the instance's public IP

Note the output values:

```
public_ip = "x.x.x.x"
ssh_command_ec2_user = "ssh -i ~/.ssh/id_ed25519 ec2-user@x.x.x.x"
```

---

## 3 — Run the Ansible playbook

Wait ~30 seconds for the instance to finish booting, then:

```bash
cd ../ansible
ansible-playbook playbooks/configure_ssh.yml
```

The playbook will:
1. Create the managed user with a locked password
2. Install the SSH public key in `~/.ssh/authorized_keys`
3. Deploy a hardened `sshd_config` (passwords, root login, and unused auth methods disabled)
4. Restart `sshd`

---

## 4 — Connect

```bash
# As the managed user (after Ansible)
ssh -i ~/.ssh/id_ed25519 deploy@<public_ip>

# As ec2-user (emergency / re-running Ansible)
ssh -i ~/.ssh/id_ed25519 ec2-user@<public_ip>
```

Password login will be rejected for all users.

---

## Tear down

```bash
cd terraform
terraform destroy
```

---

## Security notes

- `PasswordAuthentication no` and `KbdInteractiveAuthentication no` prevent all interactive password prompts.
- `PermitRootLogin no` blocks direct root SSH.
- `AllowUsers deploy ec2-user` restricts SSH to only these two accounts.
- The managed user's system password is locked (`passwd -l`) so even `su` escalation via password is blocked.
- To further restrict access, change the security group ingress CIDR to your IP.
