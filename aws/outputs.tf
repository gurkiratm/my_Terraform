output "instance_hostname" {
  description = "The public DNS name of the EC2 instance."
  value       = aws_instance.app_server.public_dns
}
output "instance" {
  description = "The ID of the EC2 instance."
  value       = aws_instance.app_server.id

}
output "instance_type" {
  description = "The type of the EC2 instance."
  value       = aws_instance.app_server.instance_type

}