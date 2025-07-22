# Secure GCP Infrastructure with Terraform

This project provisions a secure, production-grade infrastructure on Google Cloud Platform using Terraform. It includes:

- Custom VPC and Subnet with firewall rules
- GKE Regional Cluster with private endpoint, shielded nodes, gVisor sandbox, and Workload Identity
- Cloud SQL (PostgreSQL) with private IP, SSL enforcement, and backups
- Memorystore Redis (HA) over VPC
- Secure Jenkins VM with encrypted disk and limited SSH access
- Remote Terraform backend in Cloud Storage

---

## 📁 Module Structure

```
modules/
├── gke
├── jenkins
├── network
├── redis
└── sql
```

---

## 🚀 How to Use

### 1. Clone the repo
```bash
git clone https://github.com/your-org/gcp-secure-infra.git
cd gcp-secure-infra
```

### 2. Set up remote state bucket
Ensure a GCS bucket exists and has versioning + encryption enabled.
```bash
gsutil mb -l us-central1 gs://your-terraform-state-bucket
```

### 3. Fill in `terraform.tfvars`
Edit the file with your real values (project ID, IPs, passwords, etc.).

---

### 4. Initialize Terraform
```bash
terraform init
```

### 5. Review and Apply
```bash
terraform plan
terraform apply
```

---

## 🔐 Security Highlights

- **Private GKE Control Plane**
- **Shielded Nodes** with gVisor sandbox
- **Cloud SQL over Private IP** with SSL enforced
- **Memorystore VPC Only Access**
- **Encrypted Disks for Jenkins**
- **Remote Terraform State in GCS**

---

## 🧹 Cleanup
```bash
terraform destroy
```

---

## 📄 License
MIT (or your organization license)

---

Need help with CI/CD pipeline integration (e.g. GitHub Actions, Jenkins)? Let me know!
# IAC
# IAC
# IAC
