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

## RDS Module

This module creates either an AWS RDS instance or an Aurora Cluster based on the `use_aurora` variable.

### Usage Example

```hcl
module "rds" {
  source = "./modules/rds"

  name                       = "myapp-db"
  use_aurora                 = false # Set to true for Aurora Cluster

  # Common settings
  engine                     = "postgres"
  engine_version             = "14.7"
  instance_class             = "db.t3.micro"
  allocated_storage          = 20
  db_name                    = "myapp"
  username                   = "postgres"
  password                   = "securepassword"
  vpc_id                     = module.vpc.vpc_id
  subnet_private_ids         = module.vpc.private_subnets
  subnet_public_ids          = module.vpc.public_subnets
  publicly_accessible        = true

   # Parameters (override defaults max_connections/log_statement/work_mem)
  parameters = {
      max_connections = "300"
      work_mem        = "8MB"
  }
}
```

### Variables

| Name                            | Description                                                               | Type           | Default               |
| ------------------------------- | ------------------------------------------------------------------------- | -------------- | --------------------- |
| `use_aurora`                    | If true, creates Aurora Cluster. If false, creates standard RDS instance. | `bool`         | `false`               |
| `name`                          | Name identifier for resources.                                            | `string`       | -                     |
| `engine`                        | Database engine for standard RDS (e.g., `postgres`, `mysql`).             | `string`       | `postgres`            |
| `engine_cluster`                | Database engine for Aurora (e.g., `aurora-postgresql`).                   | `string`       | `aurora-postgresql`   |
| `engine_version`                | Engine version for standard RDS.                                          | `string`       | `14.7`                |
| `engine_version_cluster`        | Engine version for Aurora.                                                | `string`       | `15.3`                |
| `instance_class`                | Instance class (e.g., `db.t3.micro`).                                     | `string`       | `db.t3.micro`         |
| `allocated_storage`             | Storage size in GB (standard RDS only).                                   | `number`       | `20`                  |
| `aurora_instance_count`         | Total Aurora instances (module keeps 1 writer + `count-1` readers).       | `number`       | `2`                   |
| `db_name`                       | Database name.                                                            | `string`       | -                     |
| `username`                      | Master username.                                                          | `string`       | -                     |
| `password`                      | Master password.                                                          | `string`       | -                     |
| `vpc_id`                        | VPC ID where DB will be deployed.                                         | `string`       | -                     |
| `subnet_private_ids`            | List of private subnet IDs.                                               | `list(string)` | -                     |
| `subnet_public_ids`             | List of public subnet IDs (used if publicly_accessible is true).          | `list(string)` | -                     |
| `publicly_accessible`           | Whether the DB is publicly accessible.                                    | `bool`         | `false`               |
| `multi_az`                      | Enable Multi-AZ deployment.                                               | `bool`         | `false`               |
| `backup_retention_period`       | Number of days to keep automated backups.                                 | `number`       | `7`                   |
| `parameters`                    | Map of parameter overrides/extra values (merged with defaults).           | `map(string)`  | `{}`                  |
| `tags`                          | Common resource tags.                                                     | `map(string)`  | `{}`                  |
| `parameter_group_family_rds`    | Parameter group family for standard RDS.                                  | `string`       | `postgres15`          |
| `parameter_group_family_aurora` | Parameter group family for Aurora.                                        | `string`       | `aurora-postgresql15` |

### Built-in parameter tuning

The module always seeds both RDS and Aurora parameter groups with sane defaults for `max_connections`, `log_statement`, and `work_mem`. Provide the `parameters` map only when you need to override these defaults or add extra parameters—user supplied keys take precedence over the built-in values.

### How to change DB type

To switch between Standard RDS and Aurora Cluster, change the `use_aurora` variable:

- **Standard RDS:** Set `use_aurora = false`. Adjust `engine`, `engine_version`, and `instance_class` as needed.
- **Aurora Cluster:** Set `use_aurora = true`. Adjust `engine_cluster`, `engine_version_cluster`, and `instance_class` as needed.

To change the engine (e.g., from Postgres to MySQL), update the `engine` (for RDS) or `engine_cluster` (for Aurora) variable and ensure the `parameter_group_family_*` matches the new engine family.
