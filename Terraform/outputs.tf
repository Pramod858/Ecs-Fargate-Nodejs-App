# Output the load balancer DNS name
output "load_balancer_dns" {
    value = aws_lb.nodejs_alb.dns_name
}