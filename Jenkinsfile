pipeline {
    agent any

    environment {
        AWS_REGION = 'us-east-1'
        backend_bucket = 'dev-env-terraform-12345'
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Terraform Init') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-prod-creds'
                ]]) {
                    sh '''
                        aws sts get-caller-identity
                        terraform init -backend-config="bucket=${backend_bucket}" -backend-config="key=terraform.tfstate" -backend-config="region=${AWS_REGION}"
                    '''
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-prod-creds'
                ]]) {
                    sh '''
                        terraform plan -out=tfplan
                    '''
                }
            }
        }

        stage('Manual Approval') {
            steps {
                input message: 'Approve Terraform Apply?', ok: 'Deploy'
            }
        }

        stage('Terraform Apply') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-prod-creds'
                ]]) {
                    sh '''
                        terraform apply tfplan
                    '''
                }
            }
        }
    }

    post {
        success {
            echo 'Deployment Successful.'
        }

        failure {
            echo 'Deployment Failed.'
        }

    }
}