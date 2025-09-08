pipeline {
    agent any
    environment {
        AWS_ACCOUNT_ID = '864899858037'
        AWS_REGION = 'us-east-1'
        ECR_REPO = '2048-game'
        IMAGE_TAG = 'build-${env.BUILD_NUMBER}'
    }
    stages {

        stage('Checkout') {
            steps {
                Checkout scm
            }
        }
        
        stage('Build Docker Image') {
            steps {
                sh 'docker build -t $ECR_REPO:$IMAGE_TAG .'
            }
        }

        stage('Authenticate to ECR') {
            steps {
                sh ```
                    aws ecr get-login-password --region $AWS_REGION \
                        | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com
                ```
            }
        }

        stage ('Push Image to ECR') {
            steps {
                sh ```
                docker tag 2048-game:latest $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPO:$IMAGE_TAG
                docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPO:$IMAGE_TAG   
                ```
            }
        }

        stage ('Terraform init && Terraform apply') {
            steps {
                dir('terraform') {
                    sh ```
                    terraform init -input=false
                    terraform apply -auto-approve -input=false
                    ```
                }
            }
        }

        stage('Deploy to ECS') {
            steps {
                sh ```
                aws ecs update-service \
                    --cluster 2048-cluster \
                    --service 2048-service \
                    --force-new-deployment \
                    --region $AWS_REGION
                ```
            }
        }

        stage('Smoke test') {
            steps {
                script {
                    def appUrl = "http://2048-game-alb-1234567890.us-east-1.elb.amazonaws.com"
                    try {
                        sh "curl -f ${appUrl} || exit 1"
                        echo "Smoke test passed!"
                    } catch (err) {
                        error "Smoke test failed: ${err}"
                    }
                }
            }
        }
    }
}

post {
    always {
        echo "Pipeline finished!"
    }
    success {
        echo 'Deployment successful!'
    }
    failure {
        echo 'Deployment failed!'
    }
}