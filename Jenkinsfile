pipeline {
    agent any
    options {
        buildDiscarder logRotator(artifactDaysToKeepStr: '', artifactNumToKeepStr: '', daysToKeepStr: '7', numToKeepStr: '2')
    }
    environment {
        dockercred    = credentials('dockerhub')
        awscred       = credentials('aws-key')
        SONAR_TOKEN   = credentials('sonarqube-key')
        NEXUS_CREDS   = credentials('nexus-key')
        SONAR_URL     = 'http://<JENKINS_EC2_PRIVATE_IP>:9000'
        NEXUS_URL     = 'http://<JENKINS_EC2_PRIVATE_IP>:8081'
        ARTIFACT_NAME = "portfolio-hosting-${BUILD_NUMBER}.zip"
    }
    stages {
        stage('Checkout') {
            steps {
                checkout changelog: false, poll: false, scm: scmGit(
                    branches: [[name: '*/main']],
                    extensions: [],
                    userRemoteConfigs: [[url: 'https://github.com/DebopriyoRoy/terrafrom-portfolio-hosting.git']]
                )
            }
        }
        stage('Verify Tools') {
            parallel {
                stage('AWS Version')    { steps { sh 'aws --version' } }
                stage('Docker Version') { steps { sh 'docker -v' } }
                stage('Kubectl Version'){ steps { sh 'kubectl version --client' } }
            }
        }
        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('SonarQube') {
                    sh '''
                        sonar-scanner \
                            -Dsonar.projectKey=portfolio-deployment \
                            -Dsonar.sources=. \
                            -Dsonar.exclusions=vendor/**,**/*.java,src/**
                    '''
                }
            }
        }
        stage('Nexus Package Artifact') {
            steps {
                sh "zip -r ${ARTIFACT_NAME} . -x '*.git*' -x 'vendor/*' -x '*.zip'"
            }
        }
        stage('Upload to Nexus') {
            steps {
                sh '''
                    curl -u $NEXUS_CREDS_USR:$NEXUS_CREDS_PSW \
                        --upload-file ${ARTIFACT_NAME} \
                        ${NEXUS_URL}/repository/php-artifacts/${ARTIFACT_NAME}
                '''
            }
        }
        stage('DockerHub Login') {
            steps {
                sh 'echo $dockercred_PSW | docker login --username $dockercred_USR --password-stdin'
            }
        }
        stage('Docker Build & Push') {
            steps {
                sh '''
                    docker buildx create --use --name multiarch-builder || docker buildx use multiarch-builder
                    docker buildx build \
                        --platform linux/amd64,linux/arm64 \
                        -t debopriyoroy/portfolio-hosting:${BUILD_NUMBER} \
                        -t debopriyoroy/portfolio-hosting:latest \
                        --push \
                        .
                '''
            }
        }
        stage('Update Kubernetes Manifest') {
            steps {
                sh "sed -i 's#image: debopriyoroy/portfolio-hosting:.*#image: debopriyoroy/portfolio-hosting:${BUILD_NUMBER}#' ApplicationPrivateNAT.yaml"
            }
        }
        stage('Kubernetes Deploy') {
            steps {
                sh 'aws eks update-kubeconfig --region us-east-1 --name jenkins'
                sh 'kubectl apply -f ApplicationPrivateNAT.yaml'
            }
        }
        stage('Deploy Monitoring Stack') {
            steps {
                sh 'kubectl apply -f monitoring/namespace.yaml'
                sh 'sleep 3'
                sh 'kubectl apply -f monitoring/'
                sh 'kubectl rollout status deployment/prometheus -n monitoring --timeout=120s'
                sh 'kubectl rollout status deployment/grafana -n monitoring --timeout=120s'
            }
        }
    }
    post {
        always {
            echo "Pipeline completed - Build #${BUILD_NUMBER}"
            sh 'docker logout'
        }
        success {
            echo "Deployment successful - Image: debopriyoroy/portfolio-hosting:${BUILD_NUMBER}"
        }
        failure {
            echo "Pipeline failed - Check logs for Build #${BUILD_NUMBER}"
        }
    }
}
