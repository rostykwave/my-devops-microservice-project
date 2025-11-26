# my-devops-microservice-project

## Lesson 8–9: Terraform + Jenkins + Argo CD CI/CD

This iteration provisions the entire delivery platform (S3/DynamoDB backend, networking, ECR, EKS, Jenkins, Argo CD) with Terraform and wires a Jenkins pipeline that builds a Django image with Kaniko, pushes it to Amazon ECR, updates the Helm chart, and lets Argo CD auto-sync the change into the cluster.

### Repository layout

```
.
├── backend.tf            # Remote state (S3 + DynamoDB)
├── main.tf               # Module wiring
├── outputs.tf            # Shared outputs
├── Jenkinsfile           # Declarative pipeline for GitOps flow
├── django/               # Django sample app + Dockerfile
├── charts/django-app/    # Helm chart consumed by Argo CD
└── modules/              # Terraform modules (s3-backend, vpc, ecr, eks, jenkins, argo_cd)
```

## How to apply Terraform

1. Export AWS credentials that can create the required infrastructure and make sure the AWS CLI default region is `eu-central-1` (or update variables accordingly).
2. Initialize and review the plan:
   ```bash
   terraform init
   terraform plan
   ```
3. Provision everything:
   ```bash
   terraform apply
   ```
   Confirm with `yes`. The run creates the VPC, ECR, EKS (with OIDC for IRSA), Jenkins (via Helm), and Argo CD (via Helm + custom chart for the Application definition).
4. Export kubeconfig to talk to the new cluster if you need to inspect resources manually:
   ```bash
   aws eks update-kubeconfig --region eu-central-1 --name $(terraform output -raw eks_cluster_name)
   ```

## Jenkins pipeline (build → ECR → GitOps)

- The repository contains a ready-to-use `Jenkinsfile`. Create either a multibranch pipeline or a regular pipeline pointing to the GitHub repo/branch `lesson-8-9`.
- Install Jenkins by running Terraform; the chart already ships with the Kubernetes plugin, required agents, and a dedicated service account annotated for IRSA so that Kaniko can authenticate with ECR without static AWS keys.
- Create the GitHub PAT credential referenced in the pipeline:
  - Type: “Username with password”
  - ID: `github-token`
  - Username: GitHub login
  - Password: Personal Access Token with `repo` scope
- Trigger the pipeline. It performs two stages:
  1. **Build & Push Docker Image** – executes Kaniko inside the cluster (`django/Dockerfile` + `django/` sources) and pushes `878905833569.dkr.ecr.eu-central-1.amazonaws.com/lesson-5-ecr:v1.0.<BUILD_NUMBER>` to ECR.
  2. **Update Chart Tag in Git** – clones branch `lesson-8-9`, rewrites `charts/django-app/values.yaml` with the freshly built tag, commits, and pushes back to GitHub.
- Successful completion implies Argo CD notices the git change and syncs automatically (see next section).

## Verify Argo CD

1. Obtain the Argo CD LoadBalancer endpoint:
   ```bash
   kubectl get svc -n argocd argo-cd-argocd-server
   ```
2. Fetch the initial admin password (Terraform output also contains the command):
   ```bash
   kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d && echo
   ```
3. Log in to the UI and confirm the `django-app` application is **Synced** and **Healthy**. Each Jenkins pipeline run should create a new Helm release revision automatically once the chart tag changes.

## Monitor Jenkins jobs

1. Retrieve the Jenkins external address from `terraform output jenkins_release` / `kubectl get svc -n jenkins`.
2. Log in with the credentials configured in `modules/jenkins/values.yaml` (default user/pass: `admin` / `admin123`, change in production).
3. Open the pipeline job created earlier and inspect the console logs for the Kaniko build, ECR push, and Git commit stages.
4. Confirm the updated tag appears in `charts/django-app/values.yaml` and that Argo CD synced the new chart revision.

## Clean up

```bash
terraform destroy
```

This command tears down the cluster, Jenkins, Argo CD, and all supporting infrastructure (Helm releases, VPC, ECR, etc.).
