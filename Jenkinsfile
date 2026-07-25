pipeline {
    agent any

    parameters {
        string(
            name: 'AWS_REGION',
            defaultValue: 'us-east-1',
            description: 'AWS Region for deployment'
        )
        string(
            name: 'TERRAFORM_STATE_BUCKET',
            defaultValue: 'dev-env-terraform-12345',
            description: 'S3 bucket for Terraform state'
        )
        string(
            name: 'TERRAFORM_STATE_KEY',
            defaultValue: 'terraform.tfstate',
            description: 'Terraform state file key in S3'
        )
        string(
            name: 'AWS_CREDENTIALS_ID',
            defaultValue: 'aws-prod-creds',
            description: 'Jenkins credential ID for AWS'
        )
        choice(
            name: 'TERRAFORM_ACTION',
            choices: ['plan', 'apply', 'destroy'],
            description: 'Terraform action to perform'
        )
        booleanParam(
            name: 'AUTO_APPROVE',
            defaultValue: false,
            description: 'Skip manual approval step'
        )
    }

    environment {
        AWS_REGION = "${params.AWS_REGION}"
        TERRAFORM_STATE_BUCKET = "${params.TERRAFORM_STATE_BUCKET}"
        TERRAFORM_STATE_KEY = "${params.TERRAFORM_STATE_KEY}"
        AWS_CREDENTIALS_ID = "${params.AWS_CREDENTIALS_ID}"
        TERRAFORM_DIR = "${WORKSPACE}/terraform"
        TERRAFORM_PLAN_FILE = "tfplan-${BUILD_NUMBER}"
    }

    stages {

        stage('Checkout') {
            steps {
                script {
                    echo "🔄 Checking out source code from SCM..."
                }
                checkout scm
            }
        }

        stage('Validate Terraform') {
            steps {
                script {
                    echo "✓ Validating Terraform configuration..."
                }
                dir("${TERRAFORM_DIR}") {
                    sh '''
                        terraform fmt -check -recursive || {
                            echo "⚠️  Terraform format check failed"
                            exit 1
                        }
                        terraform validate
                    '''
                }
            }
        }

        stage('Terraform Init') {
            steps {
                script {
                    echo "🔨 Initializing Terraform..."
                }
                dir("${TERRAFORM_DIR}") {
                    withCredentials([[
                        $class: 'AmazonWebServicesCredentialsBinding',
                        credentialsId: "${AWS_CREDENTIALS_ID}"
                    ]]) {
                        sh '''
                            echo "🔍 Verifying AWS credentials..."
                            aws sts get-caller-identity --region ${AWS_REGION}
                            
                            echo "📦 Running terraform init..."
                            terraform init \
                                -backend-config="bucket=${TERRAFORM_STATE_BUCKET}" \
                                -backend-config="key=${TERRAFORM_STATE_KEY}" \
                                -backend-config="region=${AWS_REGION}" \
                                -upgrade
                        '''
                    }
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                script {
                    echo "📋 Running Terraform plan..."
                }
                dir("${TERRAFORM_DIR}") {
                    withCredentials([[
                        $class: 'AmazonWebServicesCredentialsBinding',
                        credentialsId: "${AWS_CREDENTIALS_ID}"
                    ]]) {
                        sh '''
                            terraform plan \
                                -out=${TERRAFORM_PLAN_FILE} \
                                -detailed-exitcode || exitcode=$?
                            
                            if [ "$exitcode" -eq 1 ]; then
                                echo "❌ Terraform plan failed"
                                exit 1
                            fi
                            
                            # exitcode 0 = no changes, 2 = changes detected
                            echo "Plan saved to: ${TERRAFORM_PLAN_FILE}"
                        '''
                    }
                }
            }
        }

        stage('Manual Approval') {
            when {
                expression { params.AUTO_APPROVE == false }
            }
            steps {
                script {
                    try {
                        input(
                            message: "Review the Terraform plan above. Approve ${params.TERRAFORM_ACTION}?",
                            ok: 'Deploy',
                            submitterParameter: 'APPROVED_BY'
                        )
                        env.APPROVED_BY = APPROVED_BY
                    } catch (err) {
                        error("❌ Deployment cancelled by user or timeout")
                    }
                }
            }
        }

        stage('Terraform Apply/Destroy') {
            steps {
                script {
                    echo "🚀 Executing Terraform ${params.TERRAFORM_ACTION}..."
                }
                dir("${TERRAFORM_DIR}") {
                    withCredentials([[
                        $class: 'AmazonWebServicesCredentialsBinding',
                        credentialsId: "${AWS_CREDENTIALS_ID}"
                    ]]) {
                        sh '''
                            if [ "${TERRAFORM_ACTION}" = "apply" ]; then
                                terraform apply ${TERRAFORM_PLAN_FILE}
                            elif [ "${TERRAFORM_ACTION}" = "destroy" ]; then
                                terraform destroy -auto-approve
                            else
                                echo "⚠️  Unknown action: ${TERRAFORM_ACTION}"
                                exit 1
                            fi
                        '''
                    }
                }
            }
        }

        stage('Generate Report') {
            when {
                expression { params.TERRAFORM_ACTION == 'apply' }
            }
            steps {
                script {
                    echo "📊 Generating deployment report..."
                }
                dir("${TERRAFORM_DIR}") {
                    withCredentials([[
                        $class: 'AmazonWebServicesCredentialsBinding',
                        credentialsId: "${AWS_CREDENTIALS_ID}"
                    ]]) {
                        sh '''
                            terraform show -json > tfstate-${BUILD_NUMBER}.json || true
                            echo "State exported to: tfstate-${BUILD_NUMBER}.json"
                        '''
                    }
                }
            }
        }
    }

    post {
        success {
            script {
                def approverInfo = env.APPROVED_BY ? " (Approved by: ${env.APPROVED_BY})" : " (Auto-approved)"
                echo """
                ✅ Deployment Successful${approverInfo}
                Build: ${BUILD_URL}
                Terraform Action: ${params.TERRAFORM_ACTION}
                AWS Region: ${params.AWS_REGION}
                """
            }
        }

        failure {
            script {
                echo """
                ❌ Deployment Failed
                Build: ${BUILD_URL}
                Terraform Action: ${params.TERRAFORM_ACTION}
                AWS Region: ${params.AWS_REGION}
                Check logs above for details.
                """
            }
        }

        always {
            script {
                echo "🧹 Cleaning up temporary files..."
                sh '''
                    rm -f ${TERRAFORM_DIR}/${TERRAFORM_PLAN_FILE} || true
                '''
            }
        }
    }
}