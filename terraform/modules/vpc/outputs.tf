output "vpc" {
  value = aws_vpc.react_app
}

output "subnet1" {
  value = aws_subnet.react_app_subnet1
}

output "subnet2" {
  value = aws_subnet.react_app_subnet2
}

