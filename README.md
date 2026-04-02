# End-to-End CI/CD Pipeline — PHP Portfolio on AWS EKS

> **Automated two-phase DevOps pipeline**: Terraform provisions AWS infrastructure → Jenkins CI/CD builds, tests, packages, and deploys a PHP portfolio website to AWS EKS running on private subnets.

![Jenkins](https://img.shields.io/badge/Jenkins-D24939?style=flat&logo=jenkins&logoColor=white)
![Terraform](https://img.shields.io/badge/Terraform-7B42BC?style=flat&logo=terraform&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-2496ED?style=flat&logo=docker&logoColor=white)
![Kubernetes](https://img.shields.io/badge/Kubernetes-326CE5?style=flat&logo=kubernetes&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-FF9900?style=flat&logo=amazon-aws&logoColor=white)
![SonarQube](https://img.shields.io/badge/SonarQube-4E9BCD?style=flat&logo=sonarqube&logoColor=white)
![Nexus](https://img.shields.io/badge/Nexus-Repository-1B1C30?style=flat&logo=sonatype&logoColor=white)

---

## Configuration

Before deploying, replace the following placeholders with your actual values:

| Placeholder | Description | Example |
|-------------|-------------|---------|
| `<JENKINS_EC2_PUBLIC_IP>` | Elastic IP of your Jenkins EC2 instance | Your EC2 public IP |
| `<JENKINS_EC2_PRIVATE_IP>` | Private IP of Jenkins EC2 within the VPC | Typically `10.0.x.x` |
| `<EKS_NODE_PRIVATE_IP>` | Private IP of the EKS worker node | Typically `10.0.x.x` |
| `<VPC_CIDR>` | CIDR block of your VPC | e.g. `10.0.0.0/16` |

> **Security note:** Never commit real IP addresses to a public repository. Use environment variables or parameter stores for sensitive infrastructure details.

---

## Architecture Diagram

![CI/CD Pipeline Architecture](./pipeline_diagram.png)

> *Full two-phase flow: Terraform infrastructure provisioning → Jenkins CI/CD pipeline → AWS EKS deployment*

---

## Project Overview

This project demonstrates a **production-grade, fully automated DevOps workflow** split into two interconnected phases:

| Phase | Description |
|-------|-------------|
| **Phase 1 — Infrastructure** | Jenkins triggers a Terraform pipeline that provisions the entire AWS environment (VPC, subnets, NAT Gateway, EC2, IAM, S3) |
| **Phase 2 — Application CI/CD** | On every `git push`, Jenkins runs a 9-stage pipeline: code quality → artifact packaging → multi-arch Docker build → EKS deployment |

**Live traffic flow:**
```
Browser → <JENKINS_EC2_PUBLIC_IP>:30082 (Jenkins EC2, public subnet)
              ↓ nginx reverse proxy
         <EKS_NODE_PRIVATE_IP>:30082  (EKS node, private subnet — no public IP)
              ↓
         PHP portfolio pod → port 80
```

---

## Tech Stack

| Category | Tool / Service |
|----------|---------------|
| CI/CD Orchestration | Jenkins (Dockerised, custom image) |
| Infrastructure as Code | Terraform (modular — VPC, IAM, EC2, S3) |
| Code Quality | SonarQube 9.x (Dockerised, quality gate enforced) |
| Artifact Repository | Nexus Repository Manager (raw ZIP artifacts) |
| Container Registry | DockerHub (`debopriyoroy/portfolio-hosting`) |
| Container Build | Docker Buildx + QEMU (multi-platform: amd64 + arm64) |
| Container Orchestration | AWS EKS Auto Mode (Kubernetes 1.35) |
| Networking | VPC, public/private subnets, NAT Gateway, nginx reverse proxy |
| Cloud | AWS (us-east-1) — EC2, EKS, S3, IAM, VPC |

---

## Repository Structure

```
terrafrom-portfolio-hosting/
├── Jenkinsfile                  # 9-stage CI/CD pipeline definition
├── ApplicationPrivateNAT.yaml   # Active K8s Deployment + NodePort Service
├── Application.yaml             # Original manifest (reference)
├── ApplicationDocker.yaml       # Alternate manifest (LoadBalancer variant)
├── Dockerfile                   # PHP/Apache container image
├── sonar-project.properties     # SonarQube project config
├── composer.json                # PHP dependencies (PHPMailer)
├── index.html                   # Portfolio frontend
├── send-email.php               # Contact form backend
└── README.md
```

---

## Phase 1 — Terraform Infrastructure

**Repository:** [ci-cd-terraform](https://github.com/DebopriyoRoy/ci-cd-terraform)

### AWS Resources Provisioned

| Module | Resource | Name |
|--------|----------|------|
| VPC | VPC | ci-cd-vpc (<VPC_CIDR>) |
| VPC | Public Subnets (×2) | ci-cd-subnet-public1/2-us-east-1a/b |
| VPC | Private Subnets (×2) | ci-cd-subnet-private1/2-us-east-1a/b |
| VPC | Internet Gateway | ci-cd-igw |
| VPC | NAT Gateway | ci-cd-nat (public subnet) |
| VPC | Route Tables | public + private (with correct associations) |
| IAM | Role + Instance Profile | ec2-from-jenkins |
| EC2 | Application Instance | jenkins-on-docker (t3.large) |
| S3 | Artifact + State bucket | Versioning, AES-256, lifecycle policy |

### Terraform Pipeline Stages

```
Checkout → Version Check → Init → Validate → Format Check → Plan → Apply → Show Outputs
                                                                              ↓
                                                                    [optional Destroy]
```

### Jenkins Pipeline (Infrastructure)

```groovy
pipeline {
    agent any
    environment {
        cred = credentials('aws-key')
    }
    stages {
        stage('Checkout') {
            steps {
                checkout scmGit(
                    branches: [[name: '*/main']],
                    userRemoteConfigs: [[url: 'https://github.com/DebopriyoRoy/ci-cd-terraform.git']]
                )
            }
        }
        stage('Init')     { steps { sh 'terraform init' } }
        stage('Validate') { steps { sh 'terraform validate' } }
        stage('Plan')     { steps { sh 'terraform plan' } }
        stage('Apply') {
            steps {
                timeout(time: 25, unit: 'MINUTES') {
                    sh 'terraform apply -auto-approve'
                }
            }
        }
    }
    post {
        failure { sh 'terraform destroy -auto-approve' }
        success { echo 'Infrastructure provisioned successfully.' }
    }
    parameters {
        booleanParam(name: 'DESTROY', defaultValue: false,
            description: 'Set to true to trigger terraform destroy')
    }
}
```

---

## Phase 2 — Application CI/CD Pipeline

### Pipeline Stages

```
git push (main)
     │
     ▼
Stage 1 · Checkout
     │    Pull source from GitHub
     ▼
Stage 2 · Verify Tools (parallel)
     │    aws --version | docker -v | kubectl version
     ▼
Stage 3 · SonarQube Analysis
     │    sonar-scanner inside withSonarQubeEnv
     │    Project key: portfolio-deployment
     │    Excludes: vendor/**, **/*.java, src/**
     ▼
Stage 4 · Nexus Package Artifact
     │    zip -r portfolio-hosting-${BUILD_NUMBER}.zip
     ▼
Stage 5 · Upload to Nexus
     │    curl PUT → http://<JENKINS_EC2_PRIVATE_IP>:8081/repository/php-artifacts/
     ▼
Stage 6 · DockerHub Login
     │    docker login --password-stdin
     ▼
Stage 7 · Docker Build & Push
     │    Buildx multi-platform: linux/amd64 + linux/arm64 (via QEMU)
     │    Tags: :${BUILD_NUMBER} and :latest
     │    Push → debopriyoroy/portfolio-hosting
     ▼
Stage 8 · Update Kubernetes Manifest
     │    sed -i replaces image tag in ApplicationPrivateNAT.yaml
     ▼
Stage 9 · Kubernetes Deploy
          aws eks update-kubeconfig --region us-east-1 --name jenkins
          kubectl apply -f ApplicationPrivateNAT.yaml
```

### Full Jenkinsfile

```groovy
pipeline {
    agent any
    options {
        buildDiscarder logRotator(daysToKeepStr: '7', numToKeepStr: '2')
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
            steps { sh "zip -r ${ARTIFACT_NAME} . -x '*.git*' -x 'vendor/*' -x '*.zip'" }
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
            steps { sh 'echo $dockercred_PSW | docker login --username $dockercred_USR --password-stdin' }
        }
        stage('Docker Build & Push') {
            steps {
                sh '''
                    docker buildx create --use --name multiarch-builder || docker buildx use multiarch-builder
                    docker buildx build \
                        --platform linux/amd64,linux/arm64 \
                        -t debopriyoroy/portfolio-hosting:${BUILD_NUMBER} \
                        -t debopriyoroy/portfolio-hosting:latest \
                        --push .
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
    }
    post {
        always  { sh 'docker logout' }
        success { echo "Deployment successful — Image: debopriyoroy/portfolio-hosting:${BUILD_NUMBER}" }
        failure { echo "Pipeline failed — Check logs for Build #${BUILD_NUMBER}" }
    }
}
```

---

## Kubernetes Manifest (ApplicationPrivateNAT.yaml)

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: portfolio-deployment
  labels:
    app: portfolio
spec:
  replicas: 2
  selector:
    matchLabels:
      app: portfolio
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 0
      maxSurge: 1
  template:
    metadata:
      labels:
        app: portfolio
    spec:
      tolerations:
      - key: "eks.amazonaws.com/compute-type"
        operator: "Equal"
        value: "auto"
        effect: "NoSchedule"
      containers:
      - name: portfolio-website
        image: debopriyoroy/portfolio-hosting:latest
        imagePullPolicy: Always
        ports:
        - containerPort: 80
        resources:
          requests:
            cpu: "100m"
            memory: "128Mi"
          limits:
            cpu: "500m"
            memory: "256Mi"
        livenessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 10
          periodSeconds: 10
          failureThreshold: 3
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 5
          failureThreshold: 3
---
apiVersion: v1
kind: Service
metadata:
  name: portfolio-service
spec:
  type: NodePort
  selector:
    app: portfolio
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
    nodePort: 30082
```

---

## EKS Cluster Configuration

| Property | Value |
|----------|-------|
| Cluster name | jenkins |
| Region | us-east-1 |
| Kubernetes version | 1.35 |
| Mode | EKS Auto Mode |
| Node instance | c6g.large (ARM64, Bottlerocket OS) |
| Node subnet | private subnet only (no public IP) |
| API endpoint | Public and Private |
| NAT Gateway | Required for private node image pulls |

---

## Jenkins Toolchain Setup

All three tools run as Docker containers on the Jenkins EC2 (`<JENKINS_EC2_PRIVATE_IP>`):

| Tool | Image | Port | Purpose |
|------|-------|------|---------|
| Jenkins | custom-jenkins | 8080 | Pipeline orchestration |
| SonarQube | sonarqube:community | 9000 | Static analysis + quality gate |
| Nexus | sonatype/nexus3 | 8081 | Raw ZIP artifact repository |

### Jenkins Credentials Required

| ID | Type | Used For |
|----|------|----------|
| `dockerhub` | Username/Password | DockerHub image push |
| `aws-key` | AWS Credentials | EKS kubeconfig + AWS CLI |
| `sonarqube-key` | Secret Text | SonarQube analysis token |
| `nexus-key` | Username/Password | Nexus artifact upload |

---

## Key Engineering Challenges Solved

| Challenge | Root Cause | Fix |
|-----------|------------|-----|
| Pods stuck in Pending | EKS Auto Mode requires specific toleration | Added `eks.amazonaws.com/compute-type: auto` toleration |
| `ImagePullBackOff` on private nodes | No NAT Gateway — nodes couldn't reach internet | Created NAT Gateway in public subnet + updated private route tables |
| `sed: unknown option to 's'` | Pipe `\|` delimiter conflicted with image path | Switched sed delimiter from `\|` to `#` |
| ARM64/x86 architecture mismatch | Jenkins EC2 is x86, EKS nodes are ARM64 | Multi-platform Buildx build with QEMU |
| ECR auth ordering failure | `get-login-token` called after buildx push | Switched registry from ECR to DockerHub |
| SonarQube false positives | `.java` files detected in PHP project | Added `**/*.java,src/**` to exclusions |
| App unreachable from browser | EKS node is private — no public IP | nginx reverse proxy on Jenkins EC2 |

---

## Prerequisites

### Jenkins Credentials

Create these in Jenkins → Manage Jenkins → Credentials:

```
dockerhub      → DockerHub username + password
aws-key        → AWS Access Key ID + Secret Access Key
sonarqube-key  → SonarQube Global Analysis Token (Secret Text)
nexus-key      → Nexus username + password
```

### EC2 System Settings (for SonarQube/Elasticsearch)

```bash
sudo sysctl -w vm.max_map_count=262144
sudo sysctl -w fs.file-max=65536
```

### nginx Reverse Proxy (on Jenkins EC2)

```bash
sudo yum install nginx -y

sudo tee /etc/nginx/conf.d/portfolio.conf > /dev/null <<'EOF'
server {
    listen 30082;
    location / {
        proxy_pass http://<EKS_NODE_PRIVATE_IP>:30082;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
EOF

sudo systemctl enable nginx && sudo systemctl start nginx
```

---

## Quick Reference

```bash
# Check pod status
kubectl get pods --all-namespaces

# Check nodes
kubectl get nodes -o wide

# Check service
kubectl get service portfolio-service

# Describe a failing pod
kubectl describe pod <pod-name>

# View pod logs
kubectl logs <pod-name>

# Restart deployment
kubectl rollout restart deployment/portfolio-deployment

# Check nginx proxy
sudo systemctl status nginx
```
---

## Author

**Debopriyo Roy** — Cloud & DevOps Engineer  
[GitHub](https://github.com/DebopriyoRoy) · [DockerHub](https://hub.docker.com/u/debopriyoroy)
