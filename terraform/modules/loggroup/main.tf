resource "aws_cloudwatch_log_group" "react_app" {
  name ="${var.app_name}/${var.env}"
}
