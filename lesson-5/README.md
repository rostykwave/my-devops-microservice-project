# Lesson 5: Terraform Infrastructure on AWS

This project creates infrastructure on AWS using Terraform. It includes S3 backend setup, network infrastructure (VPC), and ECR repository.
Built on terraform v1.12.2

## Project Structure

```
lesson-5/
│
├── main.tf                  # Main file for connecting modules
├── backend.tf               # Backend configuration for states (S3 + DynamoDB)
├── outputs.tf               # General resource outputs
│
├── modules/                 # Directory with all modules
│   │
│   ├── s3-backend/          # Module for S3 and DynamoDB
│   │   ├── s3.tf            # S3 bucket creation
│   │   ├── dynamodb.tf      # DynamoDB creation
│   │   ├── variables.tf     # Variables for S3
│   │   └── outputs.tf       # Output information about S3 and DynamoDB
│   │
│   ├── vpc/                 # Module for VPC
│   │   ├── vpc.tf           # VPC, subnets, Internet Gateway creation
│   │   ├── routes.tf        # Routing configuration
│   │   ├── variables.tf     # Variables for VPC
│   │   └── outputs.tf       # Output information about VPC
│   │
│   └── ecr/                 # Module for ECR
│       ├── ecr.tf           # ECR repository creation
│       ├── variables.tf     # Variables for ECR
│       └── outputs.tf       # Repository URL output
│
└── README.md                # Project documentation
```

## Module Descriptions

### s3-backend

This module creates an S3 bucket for storing Terraform state files and a DynamoDB table for state locking. This ensures secure collaboration on infrastructure.

### vpc

This module creates a Virtual Private Cloud (VPC) with:

- Public and private subnets.
- Internet Gateway for internet access from public subnets.
- NAT Gateway for internet access from private subnets.
- Route tables.

### ecr

This module creates an Elastic Container Registry (ECR) repository for storing Docker images. Includes automatic image scanning for vulnerabilities on push.

## Commands for Initialization and Execution

### First Run (Bootstrap)

Since the S3 bucket for state doesn't exist yet, follow these steps:

1. **Comment out the `backend "s3"` block** in the `backend.tf` file.
2. **Initialize Terraform locally**:
   ```bash
   terraform init
   ```
3. **Create S3 bucket and DynamoDB table**:
   ```bash
   terraform apply -target=module.s3_backend
   ```
4. **Uncomment the `backend "s3"` block** in the `backend.tf` file.
5. **Migrate state to S3**:
   ```bash
   terraform init
   ```
   (Press `yes` when asked about state migration).

### Regular Run

After the initial setup, use standard commands:

1. **Terraform Initialization**:
   Downloads required providers and modules, and configures the backend.

   ```bash
   terraform init
   ```

2. **Review Change Plan**:
   Shows which resources will be created, modified, or deleted.

   ```bash
   terraform plan
   ```

3. **Apply Changes**:
   Creates infrastructure in AWS.

   ```bash
   terraform apply
   ```

4. **Destroy Infrastructure**:
   Removes all created resources.
   ```bash
   terraform destroy
   ```
