output "private_subnet_ids" {
   value = {
     for key,subnet in aws_subnet.private_subnet: key => subnet.id
   }
 }

output "private_sg_ids" {
   value = {
     for key, sg in aws_security_group.private_sg: key => sg.id
   }
 }


# output "private_subnet_fastapi_id" {
#   value = aws_subnet.private_subnet["fastapi"].id
# }
#
# output "private_subnet_mariadb_id" {
#   value = aws_subnet.private_subnet["mariadb"].id
# }
#
# output "private_sg_fastapi_id" {
#   value = aws_security_group.private_sg["fastapi"].id
# }
#
# output "private_sg_mariadb_id" {
#   value = aws_security_group.private_sg["mariadb"].id
# }