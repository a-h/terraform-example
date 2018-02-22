resource "aws_ecs_service" "wordpress" {
  name                               = "${var.environment}-wordpress"
  cluster                            = "${aws_ecs_cluster.ecs_cluster_database.id}"
  task_definition                    = "${aws_ecs_task_definition.wordpress.arn}"
  desired_count                      = 1
  iam_role                           = "${aws_iam_role.wordpress.name}"
  deployment_minimum_healthy_percent = 100

  load_balancer {
    target_group_arn = "${aws_alb_target_group.wordpress.arn}"
    container_name   = "${var.environment}-wordpress"
    container_port   = 80
  }
}

data "aws_iam_policy_document" "wordpress_task_assume_role_policy_document" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "wordpress_task_role" {
  name               = "${var.environment}-wordpress-ecs-task-role"
  assume_role_policy = "${data.aws_iam_policy_document.wordpress_task_assume_role_policy_document.json}"
}

resource "aws_ecs_task_definition" "wordpress" {
  family                = "${var.environment}-wordpress"
  container_definitions = "${data.template_file.wordpress.rendered}"
  task_role_arn         = "${aws_iam_role.wordpress_task_role.arn}"
}

data "template_file" "wordpress" {
  template = "${file("ecs-task-wordpress.json")}"

  vars {
    name          = "${var.environment}-wordpress"
    tag           = "${var.wordpress_image_tag}"
    db_host       = "${aws_rds_cluster.aurora_cluster.endpoint}:${aws_rds_cluster.aurora_cluster.port}"
    db_user       = "${var.master_username}"
    db_password   = "${var.master_password}"
    db_name       = "${var.master_database}"
    log-group     = "${local.ecs_log_group_name}"
    region        = "${var.region}"
  }
}

resource "aws_alb_target_group" "wordpress" {
  name     = "${var.environment}-wordpress"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "${aws_vpc.vpc.id}"

  tags {
    Name        = "${var.environment}-wordpress"
    ManagedBy   = "terraform"
    Environment = "${var.environment}"
  }

  depends_on = [
    "aws_alb.wordpress",
  ]
}

data "aws_iam_policy_document" "wordpress_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ecs.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "wordpress" {
  name               = "${var.environment}-wordpress-iam-role"
  assume_role_policy = "${data.aws_iam_policy_document.wordpress_role_policy.json}"
}

resource "aws_iam_role_policy_attachment" "wordpress" {
  role       = "${aws_iam_role.wordpress.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceRole"
}

resource "aws_alb" "wordpress" {
  name               = "${var.environment}-wordpress"
  internal           = false
  load_balancer_type = "application"
  subnets            = ["${aws_subnet.public.*.id}"]
  security_groups    = ["${aws_security_group.wordpress.id}"]

  tags {
    Name        = "${var.environment}-wordpress"
    ManagedBy   = "terraform"
    Environment = "${var.environment}"
  }
}

output "wordpress_http_endpoint" {
  value = "${aws_alb.wordpress.dns_name}"
}

resource "aws_alb_listener" "wordpress" {
  load_balancer_arn = "${aws_alb.wordpress.id}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${aws_alb_target_group.wordpress.id}"
    type             = "forward"
  }
}

resource "aws_security_group" "wordpress" {
  name   = "${var.environment}-wordpress-alb-sg"
  vpc_id = "${aws_vpc.vpc.id}"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name        = "${var.environment}-wordpress"
    ManagedBy   = "terraform"
    Environment = "${var.environment}"
  }
}
