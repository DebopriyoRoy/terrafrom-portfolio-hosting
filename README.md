# Terraform CI/CD Infrastructure

Provisions AWS infrastructure using **Terraform executed from Jenkins**.
The infrastructure is modular and includes **VPC networking, IAM roles,
EC2 compute, and an S3 storage layer** for artifacts and infrastructure
data.

------------------------------------------------------------------------

# Architecture Overview

The pipeline provisions the following components:

Jenkins │ ▼ Terraform │ ├── VPC Module │ ├── VPC │ ├── Public Subnets │
├── Private Subnets │ ├── Internet Gateway │ ├── Route Tables │ └── S3
VPC Endpoint │ ├── IAM Module │ └── EC2 Role + Instance Profile │ ├──
EC2 Module │ └── Application Instance │ └── S3 Module └── Secure
artifact + state storage

------------------------------------------------------------------------

# Resources Created

  ----------------------------------------------------------------------------------------------
  Module                  Resource                Name in AWS
  ----------------------- ----------------------- ----------------------------------------------
  vpc                     VPC                     crt-from-jenkins

  vpc                     Public subnets          crt-from-jenkins-subnet-public1-us-east-1a,
                                                  ...-1b

  vpc                     Private subnets         crt-from-jenkins-subnet-private1-us-east-1a,
                                                  ...-1b

  vpc                     Internet Gateway        crt-from-jenkins-igw

  vpc                     Public route table      crt-from-jenkins-rtb-public

  vpc                     Private route tables    crt-from-jenkins-rtb-private\*

  vpc                     S3 VPC endpoint         crt-from-jenkins-vpce-s3

  vpc                     Security group          crt-from-jenkins-ec2-sg

  iam                     IAM role + instance     ec2-from-jenkins
                          profile                 

  ec2                     EC2 instance            crtd-from-jenkins

  s3                      S3 bucket               crt-from-jenkins-bucket

  s3                      Versioning              Enabled

  s3                      Server-side encryption  AES-256

  s3                      Public access block     Enabled

  s3                      Lifecycle policy        Archive after 30 days, delete after 90
  ----------------------------------------------------------------------------------------------

------------------------------------------------------------------------

# S3 Bucket Details

The Terraform configuration provisions a **secure S3 bucket designed for
CI/CD operations**.

Security: - Private bucket (no public access) - Public access fully
blocked - AES-256 server-side encryption

Data Protection: - Object versioning enabled - Prevents accidental
overwrites - Allows rollback of CI/CD artifacts

Cost Optimization: Lifecycle rule automatically: - Moves non-current
versions to STANDARD_IA after 30 days - Deletes non-current objects
after 90 days

------------------------------------------------------------------------

# Prerequisites

Configure AWS credentials in Jenkins.

Create two secret text credentials:

aws-access-key-id aws-secret-access-key

------------------------------------------------------------------------

# Jenkins Pipeline For Creation and Destroy
.
``` groovy
pipeline{
    agent any
    environment{
        cred = credentials('aws-key')
    }
    stages{
        stage('checkout'){
            steps{
                checkout scmGit(branches: [[name: '*/main']], extensions: [], userRemoteConfigs: [[url: 'https://github.com/DebopriyoRoy/terrafrom-portfolio-hosting.git']])
            }
        }
        stage('Init'){
            steps{
                sh 'terraform init'
            }
        }
        stage('Plan'){
            steps{
                sh 'terraform plan'
            }
        }
        stage('Apply'){
            steps{
				timeout(time: 25, unit: 'MINUTES'){
                sh 'terraform apply -auto-approve'
            }
          }
		}  
       /* stage('Destroy') {
            when {
                expression { currentBuild.result == 'FAILURE' || params.DESTROY == true }
            }
            steps {
                sh 'terraform destroy -auto-approve'
            }
        }*/
 
    }
 
    post {
        failure {
            echo 'Pipeline failed — running terraform destroy to clean up any partial infrastructure...'
            sh 'terraform destroy -auto-approve'
        }
        success {
            echo 'Pipeline completed successfully. All infrastructure is up and connected.'
        }
    }
 
    parameters {
        booleanParam(
            name: 'DESTROY',
            defaultValue: false,
            description: 'Set to true to manually trigger a full terraform destroy'
        )
    }
}       


```
-------------------------------------------------------------------------

# Infrastructure Map

VPC crt-from-jenkins │ ├── Public Subnets │ ├── public1-us-east-1a │ └──
public2-us-east-1b │ ├── Private Subnets │ ├── private1-us-east-1a │ └──
private2-us-east-1b │ ├── Route Tables │ ├── public │ └── private │ ├──
Internet Gateway │ ├── S3 VPC Endpoint │ ├── EC2 Instance │ └── S3
Bucket crt-from-jenkins-bucket ├── Versioning ├── Encryption └──
Lifecycle Policy

------------------------------------------------------------------------

# Purpose of This Infrastructure

This setup demonstrates a **production-style DevOps workflow**:

-   Jenkins orchestrates infrastructure deployment
-   Terraform provisions AWS resources
-   Secure networking and IAM are configured
-   S3 stores artifacts and infrastructure data
-   EC2 runs the application workload

This architecture reflects real-world CI/CD infrastructure used in
enterprise cloud environments.
