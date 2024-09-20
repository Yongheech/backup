# 다른 모듈에서 참조할 내용 정의
output "security_group_id" {
  value = aws_security_group.this.id
}