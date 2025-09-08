pipeline {
    agent {
        docker {
            image 'jenkins-agent-tools'
            args '-v /var/run/docker.sock:/var/run/docker.sock'
        }
    }

    environment {
        AWS_ACCOUNT_ID = '864899858037'
        AWS_REGION = 'us-east-1'
        APP_NAME = '2048-game'
        AWS_CREDENTIALS = credentials('aws-creds')
    }
    stages {

        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/Rene-Mayhrem/CICD-2048-Mayhrem.git'
            }
        }

        stage('Build') {
            steps {
                sh 'echo "Building project..."'
            }
        }

        stage('Check Tools') {
            steps {
                sh """
                echo '--- Checking Docker ---'
                docker --version || echo 'Docker not installed'

                echo '--- Checking Terraform ---'
                terraform --version || echo 'Terraform not installed'

                echo '--- Checking AWS CLI ---'
                aws --version || echo 'AWS CLI not installed'
                """
            }
        }

        stage('Test AWS CLI') {
            steps {
                sh "aws sts get-caller-identity"
            }
        }


        
        stage('Build Docker Image') {
            steps {
                sh 'docker build -t $APP_NAME .'
            }
        }

        stage('Authenticate to ECR') {
            steps {
                sh """
                    aws ecr get-login-password --region $AWS_REGION \
                        | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com
                """
            }
        }

        stage ('Push Image to ECR') {
            steps {
                sh """
                docker tag $APP_NAME:latest $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$APP_NAME:latest
                docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$APP_NAME:latest   
                """
            }
        }

        stage ('Terraform init && Terraform apply') {
            steps {
                dir('terraform') {
                    sh """
                    terraform init 
                    terraform apply -auto-approve \
                        -var="aws_region=$AWS_REGION" \
                        -var="aws_account_id=$AWS_ACCOUNT_ID" \
                        -var="app_name=$APP_NAME"
                    """
                }
            }
        }


        stage('Smoke test') {
            steps {
                dir('terraform') {
                    script {
                        def_alb_dns = sh(script: "terraform output -raw -alb_dns_name", returnStdout: true).trim()
                        sh "curl -I http://$alb_dns"
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