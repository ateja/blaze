# Blaze Server

The Blaze Server project serves as a foundational template for developing web applications. This template is  designed to streamline the development process by providing bare minimum essential components and configurations. I find it useful to use as a starting point for my apps. Key features of the Blaze Server include:

- **Simple Server Architecture**: A minimalistic server setup that ensures ease of deployment and scalability.
- **API Key Authentication**: Secure access management through API keys, which are generated and managed to ensure robust authentication mechanisms.
- **Docker Integration**: A comprehensive Dockerfile is included to facilitate the seamless building and deployment of containerized applications.
- **Kubernetes Configuration via Helm**: Predefined Kubernetes configurations using Helm charts to simplify the orchestration and management of containerized applications in a Kubernetes environment.
- **Azure Infrastructure Setup with Terraform**: Infrastructure as Code (IaC) is implemented using Terraform to provision and manage Azure resources efficiently, ensuring a consistent and repeatable deployment process.

  
## Prerequisites

- Docker installed
- Kubernetes cluster (Minikube or Azure AKS)
- Helm installed
- API key in `.env` file

## Local Development

### API Key Setup
The application requires an API key for authentication. The key is loaded from the environment variable `API_KEY` and is compared against the `X-API-Key` header value in requests.

### Running Locally
1. Enable hot reloading for development:
```bash
export FLASK_DEBUG=1
```

2. Test the API with authentication:
```bash
curl http://localhost:8080/files -H "X-API-Key: $(grep '^API_KEY=' .env | cut -d'=' -f2)"
```

## Kubernetes Deployment

### Minikube Deployment

#### Prerequisites
- Minikube installed
- Docker installed
- Helm installed
- API key in `.env` file

#### Deployment Steps

1. Start Minikube with Docker driver:
```bash
minikube start --driver=docker
```

2. Configure Docker to use Minikube's daemon:
```bash
eval $(minikube docker-env)
```

3. Build the Docker image:
```bash
docker build -t blaze-server:latest .
```

4. Deploy using Helm:
```bash
cd helm
helm upgrade --install blaze-server . -f values-minikube-dev.yaml --set apiKey.value=$(grep API_KEY ../.env | cut -d '=' -f2)
```

#### Verification Steps

1. Check if pods are running:
```bash
kubectl get pods
```

2. Verify the API key is correctly set in the secret:
```bash
kubectl get secret blaze-api-secret -o jsonpath='{.data.api-key}' | base64 -d
```
Compare with your local `.env` file:
```bash
cat .env | grep API_KEY
```

3. Get the service URL (run in a separate terminal as it needs to stay running):
```bash
minikube service blaze-server --url
```

4. Test the health endpoint (replace PORT with the port from step 3):
```bash
curl http://127.0.0.1:PORT/healthz
```

5. Test authenticated endpoint (replace PORT with the port from step 3):
```bash
curl -v http://127.0.0.1:PORT/files -H "X-API-Key: $(grep '^API_KEY=' ../.env | cut -d'=' -f2)"
```

### Azure AKS Deployment

#### Prerequisites
- Azure CLI installed and configured
- AKS cluster created
- Azure Container Registry (ACR) created
- API key in `.env` file

#### Deployment Steps

1. Switch to the AKS context:
```bash
kubectl config use-context blaze-aks
```

2. Apply Terraform configuration to create/update Azure resources:
```bash
cd terraform
terraform apply
```

3. Login to Azure Container Registry:
```bash
az acr login --name blazeacr
```

4. Tag the image for ACR:
```bash
docker tag blaze-server:latest blazeacr.azurecr.io/blaze-server:latest
```

5. Push the image to ACR:
```bash
docker push blazeacr.azurecr.io/blaze-server:latest
```

6. Deploy using Helm:
```bash
cd helm
helm upgrade --install blaze-server . -f values-azure-prod.yaml --set apiKey.value=$(grep API_KEY ../.env | cut -d '=' -f2)
```

#### Verification Steps

1. Check if pods are running:
```bash
kubectl get pods
```

2. Check service status:
```bash
kubectl get services
```

3. Create a port-forward tunnel to access the service (run in a separate terminal):
```bash
kubectl port-forward svc/blaze-server 8080:8080
```

4. Test the health endpoint:
```bash
curl http://localhost:8080/healthz
```

5. Test authenticated endpoint:
```bash
curl -v http://localhost:8080/files -H "X-API-Key: $(grep '^API_KEY=' ../.env | cut -d'=' -f2)"
```
### Optional Uninstallation and Cleanup

If you wish to completely remove the deployment and clean up resources, you can follow these steps:

1. Uninstall the Helm release:
   ```bash
   helm uninstall blaze-server
   ```

2. Destroy the Terraform-managed infrastructure:
   ```bash
   terraform destroy
   ```

   > **Note:** Ensure you have the correct permissions and are in the right directory where your Terraform configuration files are located before running this command. This will remove all resources defined in your Terraform configuration.

These steps are optional and should be used when you want to completely remove all resources and start fresh.

## Environment Management

### Minikube Lifecycle
- `minikube stop`: Stops the Minikube VM/container but preserves all Kubernetes resources
- `minikube start`: Starts Minikube and restores all previously created resources
- `minikube delete`: Completely removes Minikube and all resources (use this to start fresh)

### Azure AKS Lifecycle
- To delete the deployment:
```bash
helm uninstall blaze-server
```
- To delete the AKS cluster (if needed):
```bash
az aks delete --name blaze-aks --resource-group blaze-rg
```

## Troubleshooting

### Common Issues
- **Unauthorized errors**: Verify the API key in the secret matches your `.env` file
- **Service not accessible**: 
  - For Minikube: Ensure the Minikube service command is running
  - For Azure: Ensure the port-forward command is running
- **Pods not starting**: Check the pod logs with `kubectl logs <pod-name>`

### Debugging Commands
```bash
# Check pod status
kubectl get pods

# View pod logs
kubectl logs <pod-name>

# Describe pod for detailed information
kubectl describe pod <pod-name>

# Check service status
kubectl get services

# Check persistent volume claims
kubectl get pvc
```