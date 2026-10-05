output "cloudfront_domain" {
  description = "Public entry point (works without a custom domain)."
  value       = "https://${aws_cloudfront_distribution.app.domain_name}"
}

output "app_url" {
  description = "Custom URL when domain_name is set."
  value       = local.use_domain ? "https://${local.app_fqdn}" : "(no custom domain configured)"
}

output "alb_dns_name" {
  value = aws_lb.app.dns_name
}

output "asg_name" {
  value = aws_autoscaling_group.app.name
}

output "db_instance_id" {
  description = "Use this identifier for the RDS failover test."
  value       = aws_db_instance.main.identifier
}

output "db_endpoint" {
  value = aws_db_instance.main.address
}

output "db_secret_arn" {
  description = "Secrets Manager secret holding the generated master password."
  value       = aws_db_instance.main.master_user_secret[0].secret_arn
}
