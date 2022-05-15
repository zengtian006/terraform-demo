# OUTPUT
output "aws_elb_dns" {
  value = aws_elb.web.dns_name
}