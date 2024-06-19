
output "instance_ip" {
  value = aws_instance.strapi_instance.public_ip
}