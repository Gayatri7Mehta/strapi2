provider "aws" {
  region = "ap-south-1"
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "strapi_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 1337
    to_port     = 1337
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "strapi" {
  ami                   = "ami-0f58b397bc5c1f2e8"
  instance_type         = "t2.micro"
  subnet_id             = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.strapi_sg.id] 

  user_data = <<-EOF
                #!/bin/bash
                sudo apt update
                curl -fsSL https://deb.nodesource.com/setup_20.x -o nodesource_setup.sh
                sudo bash -E nodesource_setup.sh
                sudo apt update && sudo apt install nodejs -y
                sudo npm install -g yarn && sudo npm install -g pm2
                echo -e "skip\n" | npx create-strapi-app simple-strapi --quickstart
                cd simple-strapi
                echo "const strapi = require('@strapi/strapi');
                strapi().start();" > server.js
                pm2 start server.js
              EOF

  tags = {
    Name = "StrapiServer"
  }
}

output "instance_ip" {
  value = aws_instance.strapi.public_ip
}
