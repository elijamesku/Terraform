output "alb_dns_name" {
  value       = aws_lb.loadbalancer.dns_name
  description = "The domain of the load balancer"

}