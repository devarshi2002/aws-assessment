output "application_url" {
  description = "HTTP URL by default; use HTTPS only after configuring a valid ACM certificate and domain"
  value       = "http://${aws_lb.app.dns_name}"
}

output "alb_dns_name" {
  value = aws_lb.app.dns_name
}

output "vpc_id" {
  value = aws_vpc.main.id
}

output "autoscaling_group_name" {
  value = aws_autoscaling_group.app.name
}

output "rds_endpoint" {
  value       = aws_db_instance.mysql.address
  description = "Private endpoint; not directly reachable from the internet"
}

output "db_secret_arn" {
  value       = aws_secretsmanager_secret.db.arn
  description = "Secret ARN only; never output the secret value"
}
