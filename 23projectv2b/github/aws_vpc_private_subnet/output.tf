output "private_subnet_fastapi_id" {
  value = aws_subnet.private_subnet["fastapi"].id
}

output "private_subnet_mariadb_id" {
  value = aws_subnet.private_subnet["mariadb"].id
}

output "private_sg_fastapi_id" {
  value = aws_security_group.private_sg["fastapi"].id
}

output "private_sg_mariadb_id" {
  value = aws_security_group.private_sg["mariadb"].id
}