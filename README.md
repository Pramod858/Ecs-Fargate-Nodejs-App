# Node.js Application on AWS ECS Fargate with Terraform and GitHub Actions

This project demonstrates how to deploy a Node.js application on AWS ECS Fargate using Terraform for infrastructure provisioning and GitHub Actions for CI/CD automation.

![Screenshot (44)](https://github.com/Pramod858/Ecs-Fargate-Nodejs-App/assets/80105491/3814b4d3-db7f-454b-b055-ed71c7fce96a)

![Screenshot (5)](https://github.com/Pramod858/Ecs-Fargate-Nodejs-App/assets/80105491/ed588d53-ba73-4266-bceb-56474db0ed82)

![Screenshot (53)](https://github.com/Pramod858/Ecs-Fargate-Nodejs-App/assets/80105491/831d19e2-ca21-4ca3-8f39-1245c9c0c7a6)

![Screenshot (54)](https://github.com/Pramod858/Ecs-Fargate-Nodejs-App/assets/80105491/c823fd38-e0bf-4879-b558-ec4f2640d36a)

## Prerequisites

- **AWS CLI**: Install from [AWS CLI](https://aws.amazon.com/cli/)
- **Terraform**: Install from [Terraform Downloads](https://www.terraform.io/downloads.html)
- **Docker**: Install from [Docker](https://www.docker.com/get-started)
- **GitHub Account**: Fork this repository to your own GitHub account

## Project Structure

- **main.tf**: Contains the main Terraform configuration
- **provider.tf**: Specifies the AWS provider
- **variables.tf**: Defines input variables for the Terraform configuration
- **output.tf**: Specifies the outputs of the Terraform configuration
- **nodejs-app-task-definition.json**: Defines the ECS task
- **.github/workflows/main.yml**: GitHub Actions workflow file for CI/CD

## Setup Instructions

### 1. Install AWS CLI

Download and install the AWS CLI from [here](https://aws.amazon.com/cli/).

### 2. Configure AWS CLI

Configure your AWS CLI with your AWS credentials and default region:

```sh
aws configure
```

### 3. Install Terraform

Download and install Terraform from [here](https://www.terraform.io/downloads.html). Follow the installation instructions for your operating system.

### 4. Clone the Repository

Clone this repository to your local machine:

```sh
git clone https://github.com/Pramod858/Ecs-Fargate-Nodejs-App.git
cd Ecs-Fargate-Nodejs-App/Terraform
```

### 5. Initialize Terraform

Navigate to the Terraform folder and initialize Terraform:

```sh
terraform init
```

### 6. Apply Terraform Configuration

Apply the Terraform configuration to create the necessary AWS resources:

```sh
terraform apply
```

Review the changes Terraform will make and confirm the apply by typing `yes` when prompted.

### 7. Fork the Repository

Fork this repository to your own GitHub account. Once forked, navigate to your forked repository's settings and add the following secrets under **Settings > Secrets and variables > Actions**:

- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_REGION`

### 8. Modify Task Definition

Update the `nodejs-app-task-definition.json` file with your AWS account ID. Replace `<your-account-id>` with your actual AWS account ID.

```json
{
  "family": "nodejs-app-task-definition",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "volumes": [],
  "cpu": "1024",
  "memory": "3072",
  "taskRoleArn": "arn:aws:iam::<your-account-id>:role/ecsTaskExecutionRole",
  "executionRoleArn": "arn:aws:iam::<your-account-id>:role/ecsTaskExecutionRole",
  "containerDefinitions": [
    {
      "name": "nodejs-app",
      "image": "<your-account-id>.dkr.ecr.us-east-1.amazonaws.com/nodejs:latest",
      "portMappings": [
        {
          "containerPort": 3000,
          "hostPort": 3000,
          "protocol": "tcp",
          "appProtocol": "http"
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/nodejs-app",
          "awslogs-region": "us-east-1",
          "awslogs-stream-prefix": "ecs"
        }
      }
    }
  ]
}
```

### 9. Run GitHub Actions Job

Navigate to the **Actions** tab of your forked repository on GitHub and manually trigger the workflow by selecting the workflow and clicking on **Run workflow**. This will build the Docker image, push it to Amazon ECR, and deploy it to Amazon ECS.

### 10. Access Your Application

After the GitHub Actions job completes successfully, retrieve the Load Balancer DNS name. You can find it in the output of the `terraform apply` command or in the AWS Management Console under the Load Balancer section.

Copy the Load Balancer URL and paste it into your browser. You should see your Node.js application running.

### 11. Destroy Terraform Resources

To clean up and destroy all resources created by Terraform, run:

```sh
terraform destroy
```

Review the resources to be destroyed and confirm the destroy by typing `yes` when prompted.

## Note:
Ensure your GitHub Actions workflow file (`.github/workflows/main.yml`) is configured.

By following these steps, you can successfully deploy your Node.js application on AWS ECS Fargate using Terraform and automate the process with GitHub Actions.
