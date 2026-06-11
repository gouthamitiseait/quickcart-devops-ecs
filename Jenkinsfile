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

                    env.AUTH_IMAGE_TAG    = "latest"
                    env.PRODUCT_IMAGE_TAG = "latest"
                    env.CART_IMAGE_TAG    = "latest"
                    env.ORDER_IMAGE_TAG   = "latest"
                    env.PAYMENT_IMAGE_TAG = "latest"
                    env.EMAIL_IMAGE_TAG   = "latest"

                    def services = ['auth','product','cart','order','payment','email']

                    for (service in services) {

                        def changed = sh(
                            script: "git diff --name-only HEAD~1 HEAD | grep '^${service}/' || true",
                            returnStatus: true
                        ) == 0

                        if (changed) {

                            echo "Changes detected in ${service}, building Docker image..."

                            def IMAGE_TAG = sh(
                                script: "git rev-parse --short HEAD",
                                returnStdout: true
                            ).trim()

                            sh """
                                aws ecr describe-repositories --repository-names ${service} --region ${ECR_REGION} || \
                                aws ecr create-repository --repository-name ${service} --region ${ECR_REGION}

                                cd ${service}

                                docker build -t ${ECR_ACCOUNT}.dkr.ecr.${ECR_REGION}.amazonaws.com/${service}:${IMAGE_TAG} .

                                aws ecr get-login-password --region ${ECR_REGION} | docker login --username AWS --password-stdin ${ECR_ACCOUNT}.dkr.ecr.${ECR_REGION}.amazonaws.com

                                docker push ${ECR_ACCOUNT}.dkr.ecr.${ECR_REGION}.amazonaws.com/${service}:${IMAGE_TAG}

                                cd ..
                            """

                            env."${service.toUpperCase()}_IMAGE_TAG" = IMAGE_TAG
                        }
                        else {
                            echo "No changes in ${service}, skipping Docker build/push."
                        }
                    }
                }
            }
        }

        stage('Terraform Init & Apply') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-creds-id'
                ]]) {

                    dir('terraform') {
                        sh """
                            terraform init
                            terraform apply -auto-approve \
                              -var="auth_image_tag=${env.AUTH_IMAGE_TAG}" \
                              -var="product_image_tag=${env.PRODUCT_IMAGE_TAG}" \
                              -var="cart_image_tag=${env.CART_IMAGE_TAG}" \
                              -var="order_image_tag=${env.ORDER_IMAGE_TAG}" \
                              -var="payment_image_tag=${env.PAYMENT_IMAGE_TAG}" \
                              -var="email_image_tag=${env.EMAIL_IMAGE_TAG}"
                        """
                    }
                }
            }
        }
    }

    post {
        success {
            echo 'Deployment successful!'
        }
        failure {
            echo 'Deployment failed!'
        }
    }
}
