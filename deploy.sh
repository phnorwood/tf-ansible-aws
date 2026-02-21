#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TF_DIR="$REPO_ROOT/terraform"
ANSIBLE_DIR="$REPO_ROOT/ansible"

# ─── colours ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
info()  { echo -e "${GREEN}[INFO]${NC}  $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; exit 1; }

# ─── 1. Prerequisite check ────────────────────────────────────────────────────
info "Checking prerequisites..."
for cmd in terraform ansible ansible-galaxy aws nc; do
  command -v "$cmd" &>/dev/null || error "'$cmd' not found — install it before running this script."
done
info "All prerequisites found."

# ─── 2. Ensure terraform.tfvars exists ────────────────────────────────────────
TFVARS="$TF_DIR/terraform.tfvars"

if [[ ! -f "$TFVARS" ]]; then
  warn "terraform/terraform.tfvars not found."
  cp "$TF_DIR/terraform.tfvars.example" "$TFVARS"
  echo
  echo "  A starter file has been copied to:"
  echo "    $TFVARS"
  echo
  echo "  Edit it to fill in your SSH keys and settings, then re-run this script."
  exit 1
fi

# ─── 3. Install Ansible collections ───────────────────────────────────────────
info "Installing Ansible collections..."
ansible-galaxy collection install -r "$ANSIBLE_DIR/requirements.yml" --upgrade -q

# ─── 4. Terraform init ────────────────────────────────────────────────────────
info "Running terraform init..."
terraform -chdir="$TF_DIR" init -upgrade -input=false

# ─── 5. Terraform apply ───────────────────────────────────────────────────────
info "Running terraform apply..."
terraform -chdir="$TF_DIR" apply -input=false -auto-approve

# ─── 6. Read outputs ──────────────────────────────────────────────────────────
PUBLIC_IP="$(terraform -chdir="$TF_DIR" output -raw public_ip)"
PRIVATE_KEY="$(terraform -chdir="$TF_DIR" output -raw ansible_private_key_path)"
MANAGED_USER="$(terraform -chdir="$TF_DIR" output -raw managed_user)"

info "Instance public IP : $PUBLIC_IP"
info "Private key        : $PRIVATE_KEY"
info "Managed user       : $MANAGED_USER"

# ─── 7. Wait for SSH port to open ─────────────────────────────────────────────
info "Waiting for SSH port 22 to open on $PUBLIC_IP..."
TIMEOUT=120
ELAPSED=0
until nc -z -w 3 "$PUBLIC_IP" 22 2>/dev/null; do
  if [[ $ELAPSED -ge $TIMEOUT ]]; then
    error "Port 22 did not open within ${TIMEOUT}s. Check the instance and security group."
  fi
  sleep 5
  ELAPSED=$((ELAPSED + 5))
  echo -n "."
done
echo
info "SSH port is open."

# Give sshd a moment to finish starting after the port accepts connections
sleep 5

# ─── 8. Run Ansible playbook ──────────────────────────────────────────────────
info "Running Ansible playbook..."
ansible-playbook \
  -i "$ANSIBLE_DIR/inventory/hosts.ini" \
  "$ANSIBLE_DIR/playbooks/configure_ssh.yml"

# ─── 9. Summary ───────────────────────────────────────────────────────────────
echo
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN} Deployment complete${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo "  Public IP  : $PUBLIC_IP"
echo "  Connect    : ssh -i $PRIVATE_KEY ${MANAGED_USER}@${PUBLIC_IP}"
echo "  Tear down  : cd terraform && terraform destroy"
echo
