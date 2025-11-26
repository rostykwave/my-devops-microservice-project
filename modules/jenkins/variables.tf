variable "cluster_name" {
  description = "The name of the Kubernetes cluster"
  type        = string
}

variable "oidc_provider_arn" {
  description = "Provider OIDC ARN"
  type        = string
}

variable "oidc_provider_url" {
  description = "Provider OIDC URL"
  type        = string
}
