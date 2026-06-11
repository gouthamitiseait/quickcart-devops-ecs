pipeline {
    agent any

    environment {
        AWS_REGION      = 'ap-south-1'
        PROJECT_NAME    = 'devops-project'
        AWS_CREDENTIALS = credentials('aws-creds-id')
        ECR_ACCOUNT     = '286668306333'
        ECR_REGION      = "${env.AWS_REGION}"
    }

    stages {

        stage('Build & Push Docker Images') {
            steps {
                script {
                    // List of microservices
                    def services = ['auth','product','cart','order','payment','email']

                    for (service in services) {
                        // Check if files in this service folder changed
                        def changed = sh(
                            script: "git diff --name-only HEAD~1 HEAD | grep '^${service}/' || true",
                            returnStatus: true
                        ) == 0

                        if (changed) {
                            echo "Changes detected in ${service}, building Docker image..."

                            // Use commit hash as image tag
                            def IMAGE_TAG = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim()
                            echo "Image tag for ${service}: ${IMAGE_TAG}"

                            sh """
                                aws ecr describe-repositories --repository-names ${service} --region ${ECR_REGION} || \
                                aws ecr create-repository --repository-name ${service} --region ${ECR_REGION}

                                cd ${service}
                                docker build -t ${ECR_ACCOUNT}.dkr.ecr.${ECR_REGION}.amazonaws.com/${service}:${IMAGE_TAG} .
                                aws ecr get-login-password --region ${ECR_REGION} | docker login --username AWS --password-stdin ${ECR_ACCOUNT}.dkr.ecr.${ECR_REGION}.amazonaws.com
                                docker push ${ECR_ACCOUNT}.dkr.ecr.${ECR_REGION}.amazonaws.com/${service}:${IMAGE_TAG}
                                cd ..
                            """

                            // Save image tag as environment variable for Terraform
                            
                            env.setProperty("${service.toUpperCase()}_IMAGE_TAG", IMAGE_TAG)

                        } else {
                            echo "No changes in ${service}, skipping Docker build/push."
                        }
                    }
                }
            }
        }

        stage('Terraform Init & Apply') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds-id']]) {
                    dir('terraform') {
                        // Pass dynamic image tags to Terraform
                        sh """
                            terraform init
                            terraform apply -auto-approve \
                                -var "auth_image_tag=${env.AUTH_IMAGE_TAG}" \
                                -var "product_image_tag=${env.PRODUCT_IMAGE_TAG}" \
                                -var "cart_image_tag=${env.CART_IMAGE_TAG}" \
                                -var "order_image_tag=${env.ORDER_IMAGE_TAG}" \
                                -var "payment_image_tag=${env.PAYMENT_IMAGE_TAG}" \
                                -var "email_image_tag=${env.EMAIL_IMAGE_TAG}"
                        """
                    }
                }
            }
        }

        stage('Build & Deploy Frontend to S3') {
            steps {
                script {
                    // Check if frontend code changed
                    def frontendChanged = sh(
                        script: "git diff --name-only HEAD~1 HEAD | grep '^frontend/' || true",
                        returnStatus: true
                    ) == 0

                    if (frontendChanged) {
                        echo "Frontend changes detected, building and deploying..."

                        // Get ALB DNS dynamically from Terraform output
                        env.ALB_DNS = sh(script: "cd terraform && terraform output -raw alb_dns_name | tr -d '\"'", returnStdout: true).trim()
                        echo "ALB DNS: ${env.ALB_DNS}"

                        sh """
                            cd frontend
                            # Replace the REACT_APP_API_URL in .env with the ALB DNS
                            sed -i 's|REACT_APP_API_URL=.*|REACT_APP_API_URL=http://${env.ALB_DNS}|' .env

                            rm -rf node_modules package-lock.json
                            npm install

                            chmod +x node_modules/.bin/*

                            export CI=false
                            npm run build

                            aws s3 sync build/ s3://devops-project-frontend-rajesh --region ${AWS_REGION}
                        """
                    } else {
                        echo "No frontend changes detected, skipping build/deploy."
                    }
                }
            }
        }
    }

    post {
        success { 
            echo 'Deployment to ECS + ALB + frontend S3 complete!' 
        }
        failure { 
            echo 'Deployment failed.' 
        }
    }
}
