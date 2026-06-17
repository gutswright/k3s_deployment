# Setup Notes

## OpenTofu state

Phase 1 uses local OpenTofu state. The state files are ignored by git.

Remote state is possible later. Local state is simpler while learning, but it
must be protected because it is the record OpenTofu uses to know which real
cloud resources it manages.

## Hetzner token

Export your Hetzner Cloud API token before running OpenTofu:

```sh
export HCLOUD_TOKEN="..."
```

Do not commit this token to git.

## SSH restriction

Create `infra/terraform/terraform.tfvars` from the example and replace the CIDR
with your current public IP address as a `/32`.

Example:

```hcl
ssh_allowed_cidrs = [
  "203.0.113.10/32"
]
```

The servers are configured by cloud-init to listen for SSH on port `2222`.
