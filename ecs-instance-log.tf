locals {
  ecs_log_group_name = "${var.environment}-${var.application}-ecs-logs"
}

resource "aws_cloudwatch_log_group" "ecs_log_group" {
  name = "${local.ecs_log_group_name}"

  tags = {
    Name        = "${var.environment}-${var.application}"
    ManagedBy   = "terraform"
    Environment = "${var.environment}"
  }
}
