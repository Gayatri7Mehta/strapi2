
**Deploy Strapi on AWS EC2 using Terraform**

**Step1: Write Terraform Code**
## Author: Ravi Prakash Yadav

Write all the code to deploy using terraform 

1. main.tf file

   ##################################

   ## SSH Key Pair Generation

   ##################################

   resource "tls\_private\_key" "strapi\_key" {

   `  `algorithm = "RSA"

   `  `rsa\_bits  = 4096

   }

   resource "aws\_key\_pair" "strapi\_keypair" {

   `  `key\_name   = "strapi-keypair2"

   `  `public\_key = tls\_private\_key.strapi\_key.public\_key\_openssh

   }

   ##################################

   ## EC2 Instance

   ##################################

   resource "aws\_instance" "strapi\_instance" {

   `  `ami           = var.ami

   `  `instance\_type = "t2.medium"

   `  `key\_name      = aws\_key\_pair.strapi\_keypair.key\_name

   `  `security\_groups = [aws\_security\_group.strapi\_sg.name]

   `  `tags = {

   `    `Name = "Ravi-Strapi-Instance"

   `  `}

   `  `provisioner "remote-exec" {

   `  `inline = [

   `    `"sudo apt-get update",

   `    `"curl -fsSL https://deb.nodesource.com/setup\_18.x | sudo -E bash -",

   `    `"sudo apt-get install -y nodejs",

   `    `"sudo apt-get install -y npm",

   `    `"sudo npm install pm2 -g",

   `    `"if [ ! -d /srv/strapi ]; then sudo git clone https://github.com/raviiai/Strapi-project-Deployment /srv/strapi; else cd /srv/strapi && sudo git pull origin master; fi",

   `    `"sudo chmod u+x /srv/strapi/generate\_env\_variables.sh\*",

   `    `"cd /srv/strapi",

   `    `"sudo ./generate\_env\_variables.sh",

   ]

   `    `connection {

   `      `type        = "ssh"

   `      `user        = "ubuntu"

   `      `private\_key = tls\_private\_key.strapi\_key.private\_key\_pem

   `      `host        = self.public\_ip

   `    `}

   `  `}

   }

   ##################################

   ## Security Group

   ##################################

   resource "aws\_security\_group" "strapi\_sg" {

   `  `name        = "strapi-security-group2"

   `  `description = "Security group for Strapi EC2 instance"

   `  `ingress {

   `    `from\_port   = 22

   `    `to\_port     = 22

   `    `protocol    = "tcp"

   `    `cidr\_blocks = ["0.0.0.0/0"]

   `  `}

   `  `ingress {

   `    `from\_port   = 1337

   `    `to\_port     = 1337

   `    `protocol    = "tcp"

   `    `cidr\_blocks = ["0.0.0.0/0"]

   `  `}

   `  `egress {

   `    `from\_port   = 0

   `    `to\_port     = 0

   `    `protocol    = "-1"

   `    `cidr\_blocks = ["0.0.0.0/0"]

   `  `}

   `  `tags = {

   `    `Name = "Strapi Security Group"

   `  `}

   }

1. variable.tf

   variable "region" {

   `  `default = "eu-west-2"

   }

   variable "ami" {

   `  `default = "ami-053a617c6207ecc7b"

   }

1. providers.tf

   terraform {

   `  `required\_providers {

   `    `aws = {

   `      `source = "hashicorp/aws"

   `      `version = "5.54.1"

   `    `}

   `  `}

   }

   provider "aws" {

   `  `region = var.region

1. outputs.tf

   output "instance\_ip" {

   `  `value = aws\_instance.strapi\_instance.public\_ip

   }

**Note: write a bash Script file to load and create env variable which is going to be used by the strapi application**

1. **generate\_env.sh**

   **#!/bin/bash**

   **# Generate random values for each environment variable**

   **APP\_KEYS=$(node -e "console.log(require('crypto').randomBytes(32).toString('hex'))")**

   **API\_TOKEN\_SALT=$(node -e "console.log(require('crypto').randomBytes(16).toString('base64'))")**

   **ADMIN\_JWT\_SECRET=$(node -e "console.log(require('crypto').randomBytes(16).toString('base64'))")**

   **TRANSFER\_TOKEN\_SALT=$(node -e "console.log(require('crypto').randomBytes(16).toString('base64'))")**

   **# Export variables**

   **export APP\_KEYS**

   **export API\_TOKEN\_SALT**

   **export ADMIN\_JWT\_SECRET**

   **export TRANSFER\_TOKEN\_SALT**

   **# Optionally, write them to a .env file**

   **echo "APP\_KEYS=${APP\_KEYS}" > .env**

   **echo "API\_TOKEN\_SALT=${API\_TOKEN\_SALT}" >> .env**

   **echo "ADMIN\_JWT\_SECRET=${ADMIN\_JWT\_SECRET}" >> .env**

   **echo "Environment variables generated and exported:"**

   **echo "APP\_KEYS=${APP\_KEYS}"**

   **echo "API\_TOKEN\_SALT=${API\_TOKEN\_SALT}"**

   **echo "ADMIN\_JWT\_SECRET=${ADMIN\_JWT\_SECRET}"**



Now we are ready for the deployment 

To deploy first we need to initialise the terraform

1. ***terraform init***

After than we need to make plan

1. ***terraform plan***

Then we need to deploy using command 

1. ***Terraform apply***

**It will look like this**

![](Aspose.Words.2ec5cb76-f0d3-42d3-b7d9-323ce2de99b3.001.png)

**Step2: Creating CI/CD Pipeline**


**Step3: CI/CD using github action**

Create a folder at main directory .github/workflow

Here create a file : stapi-deploy.yaml and add the below code 

name: Deploy Strapi Application

on:

`  `push:

`    `branches:

`      `- main

`  `pull\_request:

`    `branches:

`      `- main  

jobs:

`  `deploy:

`    `runs-on: ubuntu-latest

`    `steps:

`    `- name: Checkout code

`      `uses: actions/checkout@v2

`    `- name: Install SSH client

`      `run: sudo apt-get install openssh-client

`    `- name: SSH into EC2 instance and deploy Strapi

`      `uses: appleboy/ssh-action@master

`      `with:

`        `host: ${{ secrets.EC2\_PUBLIC\_IP }}

`        `username: ubuntu

`        `key: ${{ secrets.PRIVATE\_SSH\_KEY }}

`        `script: |

`          `cd /srv/strapi

`          `sudo git pull origin main

`          `sudo npm install        

`          `# Check if Strapi is already managed by pm2

`          `if ! sudo pm2 status | grep -q "strapi-app"; then

`            `echo "Strapi is not managed by pm2. Starting Strapi with pm2..."

`            `sudo pm2 start "npm run start --silent" --name "strapi-app"

`          `else

`            `echo "Strapi is already managed by pm2. Restarting Strapi..."

`            `sudo pm2 restart strapi-app

`          `fi


1. Setting up the Github Action

   ![](Aspose.Words.2ec5cb76-f0d3-42d3-b7d9-323ce2de99b3.002.png)

   Create Workflow and run the build

   ![](Aspose.Words.2ec5cb76-f0d3-42d3-b7d9-323ce2de99b3.003.png)

   Once it is success it will show below

   ![](Aspose.Words.2ec5cb76-f0d3-42d3-b7d9-323ce2de99b3.004.png)


We can see the application is running 

![](Aspose.Words.2ec5cb76-f0d3-42d3-b7d9-323ce2de99b3.005.png)

![](Aspose.Words.2ec5cb76-f0d3-42d3-b7d9-323ce2de99b3.006.png)

Click on Create first administator.

![](Aspose.Words.2ec5cb76-f0d3-42d3-b7d9-323ce2de99b3.007.png)

Fill all the details and click on lets’ start.

![](Aspose.Words.2ec5cb76-f0d3-42d3-b7d9-323ce2de99b3.008.png)

Strapi is running succesfully on ec2 instance.

## Author: Ravi Prakash Yadav