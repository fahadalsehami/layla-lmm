# infrastructure/scripts/setup_env.sh

#!/bin/bash

# Set environment variables
export LAYLA_ENV=${1:-dev}
export AWS_REGION="us-east-1"
export PROJECT_NAME="layla-app"

# Check requirements
check_requirements() {
    echo "Checking requirements..."
    
    # Check AWS CLI
    if ! command -v aws &> /dev/null; then
        echo "AWS CLI is not installed. Please install it first."
        exit 1
    fi
    
    # Check Terraform
    if ! command -v terraform &> /dev/null; then
        echo "Terraform is not installed. Please install it first."
        exit 1
    }
    
    # Check NVIDIA toolkit
    if ! command -v nvidia-smi &> /dev/null; then
        echo "NVIDIA toolkit is not installed. Please install it first."
        exit 1
    }
}

# Initialize infrastructure
init_infrastructure() {
    echo "Initializing infrastructure for environment: $LAYLA_ENV"
    
    # Initialize Terraform
    cd infrastructure/aws/terraform/environments/$LAYLA_ENV
    terraform init
    
    # Create S3 bucket for Terraform state
    aws s3api create-bucket \
        --bucket "layla-app-terraform-state-${LAYLA_ENV}" \
        --region $AWS_REGION
}

# Main setup
main() {
    check_requirements
    init_infrastructure
    
    echo "Infrastructure setup complete for $LAYLA_ENV environment"
}

main