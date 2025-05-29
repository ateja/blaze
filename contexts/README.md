# Kubernetes Contexts

This directory contains the kubeconfig files for different environments:

## Environments

1. `dev.yaml`: Minikube development environment
   - Local development and testing
   - Uses local Docker images
   - NodePort services

2. `aws-prod.yaml`: AWS Production environment
   - Production cluster in AWS
   - Uses ECR images
   - LoadBalancer services with NLB
   - Uses gp2 storage class

3. `azure-prod.yaml`: Azure Production environment
   - Production cluster in Azure
   - Uses ACR images
   - Internal LoadBalancer
   - Uses managed-premium storage class

## Usage

Switch between contexts using:

```bash
# Development
export KUBECONFIG=./contexts/dev.yaml
# or
kubectl config use-context blaze-dev

# AWS Production
export KUBECONFIG=./contexts/aws-prod.yaml
# or
kubectl config use-context blaze-aws-prod

# Azure Production
export KUBECONFIG=./contexts/azure-prod.yaml
# or
kubectl config use-context blaze-azure-prod
```

## Security Notes

1. Production contexts should have:
   - Separate credentials
   - RBAC restrictions
   - Audit logging enabled
   - Network policies
   
2. CI/CD should use:
   - Service accounts with limited permissions
   - Short-lived credentials
   - Environment-specific pipelines 