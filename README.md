## Prerequisites

Before using this project, ensure you have the following installed:

- [Terraform](https://www.terraform.io/downloads.html)
- [AWS CLI](https://aws.amazon.com/cli/)
- [Python 3.11](https://www.python.org/downloads/)
- [Make](https://www.gnu.org/software/make/)

## AWS Configuration

To configure your AWS credentials, run:

```bash
aws configure
```

This command will prompt you for your AWS Access Key, Secret Access Key, region, and output format. Ensure you have the necessary permissions to create S3 buckets and Lambda functions.

## Generating the Lambda Layer

To generate the Lambda layer and prepare it for deployment, use the provided Makefile:

1. Open a terminal and navigate to the project directory.
2. Run the following command:

   ```bash
   make generate-lambda-layer
   ```

This command will:
- Create the necessary directory structure.
- Install the required packages from `lambda/requirements.txt` into the specified directory.
- Zip the installed packages into `layer-data-ingestion.zip`.
- Clean up any temporary files.

## Deploying the Infrastructure with Terraform

After generating the Lambda layer, you can deploy the infrastructure using Terraform:

1. **Initialize Terraform**: Run the following command in the root of your project to initialize the Terraform working directory:

   ```bash
   terraform init
   ```

2. **Review the Terraform plan**: To see what resources will be created, run:

   ```bash
   terraform plan
   ```

3. **Apply the configuration**: To deploy the architecture, run:

   ```bash
   terraform apply
   ```

   Confirm the action when prompted. This will create the necessary AWS resources, including S3 buckets for data ingestion and the Lambda function for processing.

## Resulting Architecture

The deployed architecture will consist of:

- **S3 Buckets**: 
  - A bucket for storing Lambda layers.
  - A bucket for the destination of ingested data.
  
- **AWS Lambda Function**: A serverless function that handles data ingestion into S3, utilizing the generated Lambda layer.

By following these steps, you will set up a scalable data ingestion pipeline into AWS S3 using Lambda and Terraform.
