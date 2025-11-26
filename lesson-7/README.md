# Lesson 7: Kubernetes Cluster with EKS and Helm

This project expands on the previous infrastructure by adding an Amazon EKS cluster and deploying a Django application using Helm. It includes ECR for image storage, EKS for orchestration, and a Helm chart with HPA and ConfigMap.

## Project Structure

```
lesson-7/
│
├── main.tf                  # Main Terraform configuration
├── backend.tf               # Backend configuration (S3 + DynamoDB)
├── outputs.tf               # Outputs
│
├── modules/
│   ├── s3-backend/          # Terraform State storage
│   ├── vpc/                 # Network infrastructure
│   ├── ecr/                 # Elastic Container Registry
│   └── eks/                 # Elastic Kubernetes Service (Cluster + Node Group)
│
└── charts/
    └── django-app/          # Helm Chart for the application
        ├── templates/
        │   ├── deployment.yaml
        │   ├── service.yaml
        │   ├── hpa.yaml
        │   └── configmap.yaml
        ├── Chart.yaml
        └── values.yaml
```

## Infrastructure Components

1.  **VPC**: Networking foundation.
2.  **ECR**: Stores the Docker image for the Django application.
3.  **EKS**: Kubernetes cluster with a managed Node Group.
4.  **Helm Chart**:
    - **Deployment**: Manages the application pods with resource limits.
    - **Service**: Exposes the application via a LoadBalancer.
    - **HPA**: Automatically scales pods (2-6 replicas) based on CPU usage (>70%).
    - **ConfigMap**: Injects environment variables.

## Prerequisites

- Terraform
- AWS CLI configured
- `kubectl`
- `helm`
- Docker

## Deployment Steps

### 1. Provision Infrastructure with Terraform

Initialize and apply the Terraform configuration to create the VPC, ECR, and EKS cluster.

```bash
terraform init
terraform apply
```

_Type `yes` to confirm._

### 2. Configure kubectl

Update your kubeconfig to interact with the newly created EKS cluster.

```bash
aws eks update-kubeconfig --region eu-central-1 --name eks-cluster-demo
```

### 3. Build and Push Docker Image

Authenticate with ECR, build your image, and push it to the repository created by Terraform.

```bash
# Login to ECR
aws ecr get-login-password --region eu-central-1 | docker login --username AWS --password-stdin <YOUR_ACCOUNT_ID>.dkr.ecr.eu-central-1.amazonaws.com

# Build the image (assuming Dockerfile is in the root or specified path)
docker build -t lesson-5-ecr .

# Tag the image
docker tag lesson-5-ecr:latest <YOUR_ECR_REPO_URL>:latest

# Push to ECR
docker push <YOUR_ECR_REPO_URL>:latest
```

_Note: Replace `<YOUR_ACCOUNT_ID>` and `<YOUR_ECR_REPO_URL>` with actual values from Terraform outputs._

### 4. Deploy Application with Helm

Update `charts/django-app/values.yaml` with your ECR image repository URL, then install the chart.

```bash
# Install the chart
helm install django-app ./charts/django-app
```

### 5. Verify Deployment

Check the status of your resources.

```bash
# Check pods
kubectl get pods

# Check service (get External IP)
kubectl get svc

# Check HPA
kubectl get hpa
```

## Cleanup

To remove all resources:

```bash
helm uninstall django-app
terraform destroy
```
