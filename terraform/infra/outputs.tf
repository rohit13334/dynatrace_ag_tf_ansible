output "activegate_public_ip" {
  value = aws_instance.activegate_vm.public_ip
}

output "activegate_private_ip" {
  value = aws_instance.activegate_vm.private_ip
}

output "ssh_user" {
  value = "ec2-user"
}
