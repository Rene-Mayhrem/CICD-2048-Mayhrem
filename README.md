# 🚀 2048 Game CI/CD with Jenkins, Docker, AWS ECR & Terraform

This project demonstrates a **DevOps portfolio pipeline** using the classic **2048 game** as the application.  
It combines **Infrastructure as Code (Terraform)**, **Containerization (Docker)**, and **Continuous Integration / Continuous Deployment (CI/CD) with Jenkins**.  
The pipeline builds the app, packages it into a container, pushes the image to **Amazon Elastic Container Registry (ECR)**, and can optionally deploy it to **Amazon ECS**.

---

## 🛠️ Tech Stack
- **Application**: 2048 game (static frontend app)
- **CI/CD**: Jenkins (Declarative Pipeline)
- **Infrastructure as Code**: Terraform
- **Containerization**: Docker
- **Cloud Provider**: AWS (ECR, ECS, IAM, S3 for state backend)
- **Languages/Tools**: Groovy, HCL, Bash, AWS CLI

---

## ⚙️ Workflow Overview

1. **Code Push**  
   Developer commits and pushes code to GitHub.

2. **Jenkins Trigger**  
   Jenkins pipeline is triggered via a `Jenkinsfile`.

3. **Terraform Stage**  
   - Initializes backend (S3 + DynamoDB for state & locking).  
   - Provisions AWS infrastructure (ECR repository, IAM roles, optional ECS cluster/service).  

4. **Build & Test Stage**  
   - Installs dependencies (npm, etc.).  
   - Runs tests and builds static files.  

5. **Docker Build & Push Stage**  
   - Builds Docker image of the 2048 app.  
   ```bash

   ```
   - Tags image with both commit SHA and `latest`.  
   - Authenticates to AWS ECR and pushes images.  

6. **Deployment Stage (Optional)**  
   - Updates ECS service with the new image, or runs on EC2/Fargate.  

7. **Smoke Tests**  
   - Health check endpoint is verified.  

---

## 📂 Repository Structure

```bash
.
├── Dockerfile # Container definition for 2048 app
├── Jenkinsfile # Jenkins pipeline definition
├── terraform/ # Terraform IaC for AWS resources
│ ├── main.tf
│ ├── outputs.tf
│ └── variables.tf
├── scripts/ # Helper scripts for deployment & testing
│ ├── deploy-ecs.sh
│ └── smoke-test.sh
└── README.md
```


1. Create a repo in AWS ECR in the aws console
```bash
aws ecr create-repository --repository-name 2048-game --region us-east-1
```

2. Authenticate  Docker with ECR in aws console
```bash
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <aws_account_id>.dkr.ecr.us-east-1.amazonaws.com
```

3. Tag the local docker image
```bash
docker tag 2048-game:latest <aws_account_id>.dkr.ecr.ur-east-1.amazonaws/2048-game:mdl8thzPE6GCJWhY3YQQAT51jOE6JjZeFdbCrLlulatest
```

4. Push the docker image to ECR
```bash 
docker push <aws_account_id>.dkr.ecr.us-east-1.amazonaws.com/2048-game:latest
```

## Jenkins File
Included stages:
- Build (docker image)
- Authenticate to AWS ECR 
- Push docker image to ECR
- Deploy to ECS
- Run smoke tests
