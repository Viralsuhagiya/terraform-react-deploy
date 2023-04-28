resource "aws_ecr_repository" "react_app" {
  name = "${var.app_name}-${var.env}-ecr"
}