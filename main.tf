##################################
## SSH Key Pair Generation
##################################

resource "tls_private_key" "strapi_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "strapi_keypair" {
  key_name   = "strapi-keypair2"
  public_key = tls_private_key.strapi_key.public_key_openssh
}

##################################
## EC2 Instance
##################################

resource "aws_instance" "strapi_instance" {
  ami           = var.ami
  instance_type = "t2.medium"
  key_name      = aws_key_pair.strapi_keypair.key_name
  security_groups = [aws_security_group.strapi_sg.name]

  tags = {
    Name = "Ravi-Strapi-Instance"
  }

  provisioner "remote-exec" {
  inline = [
    "sudo apt-get update",
    "curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -",
    "sudo apt-get install -y nodejs",
    "sudo apt-get install -y npm",
    "sudo npm install pm2 -g",
    "if [ ! -d /srv/strapi ]; then sudo git clone https://github.com/raviiai/Strapi-project-Deployment /srv/strapi; else cd /srv/strapi && sudo git pull origin master; fi",
    "sudo chmod u+x /srv/strapi/generate_env_variables.sh*",
    "cd /srv/strapi",
    "sudo ./generate_env_variables.sh",
]
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = tls_private_key.strapi_key.private_key_pem
      host        = self.public_ip
    }
  }

}

##################################
## Security Group
##################################

resource "aws_security_group" "strapi_sg" {
  name        = "strapi-security-group2"
  description = "Security group for Strapi EC2 instance"

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

  tags = {
    Name = "Strapi Security Group"
  }
}
