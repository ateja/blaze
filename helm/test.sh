#!/bin/bash

# Function to test Helm chart configuration
test_chart() {
    local env=$1
    local values_file=$2
    
    echo "Testing Helm chart for $env environment..."
    
    # Test 1: Lint the chart
    echo "Running helm lint..."
    helm lint . -f $values_file
    if [ $? -ne 0 ]; then
        echo "❌ Helm lint failed for $env environment"
        return 1
    fi
    
    # Test 2: Template validation
    echo "Validating templates..."
    helm template blaze-server . -f $values_file > /dev/null
    if [ $? -ne 0 ]; then
        echo "❌ Template validation failed for $env environment"
        return 1
    fi
    
    # Test 3: Check for required values
    echo "Checking required values..."
    if ! helm template blaze-server . -f $values_file | grep -q "blaze-server"; then
        echo "❌ Required values missing in $env environment"
        return 1
    fi
    
    # Test 4: Validate environment-specific configurations
    if [ "$env" = "Minikube" ]; then
        # Check Minikube-specific configurations
        if ! helm template blaze-server . -f $values_file | grep -q "type: NodePort"; then
            echo "❌ Missing NodePort configuration for Minikube"
            return 1
        fi
        # Check for either explicit standard storage class or no storage class (which defaults to standard in Minikube)
        if ! helm template blaze-server . -f $values_file | grep -q "storageClassName: standard" && \
           ! helm template blaze-server . -f $values_file | grep -q "storageClassName: \"\""; then
            echo "❌ Storage class configuration incorrect for Minikube"
            return 1
        fi
    elif [ "$env" = "Azure" ]; then
        # Check Azure-specific configurations
        if ! helm template blaze-server . -f $values_file | grep -q "type: LoadBalancer"; then
            echo "❌ Missing LoadBalancer configuration for Azure"
            return 1
        fi
        if ! helm template blaze-server . -f $values_file | grep -q "storageClassName: managed-premium"; then
            echo "❌ Missing managed-premium storage class for Azure"
            return 1
        fi
    fi
    
    echo "✅ All configuration tests passed for $env environment"
    return 0
}

# Check if environment parameter is provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 [minikube|azure]"
    exit 1
fi

# Run tests based on the provided environment
case "$1" in
    "minikube")
        echo "Testing Minikube configuration..."
        test_chart "Minikube" "values-minikube-dev.yaml"
        ;;
    "azure")
        echo "Testing Azure configuration..."
        test_chart "Azure" "values-azure-prod.yaml"
        ;;
    *)
        echo "Invalid environment. Use 'minikube' or 'azure'"
        exit 1
        ;;
esac

# Exit with the test result
exit $? 