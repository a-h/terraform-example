resource "aws_ecs_cluster" "ecs_cluster_database" {
  name = "${var.environment}-${var.application}-database"
}

resource "aws_autoscaling_group" "ecs_cluster_database" {
  name                 = "${var.environment}-${var.application}-database-asg"
  availability_zones   = ["${var.availability_zones}"]
  launch_configuration = "${aws_launch_configuration.ecs_cluster_database.name}"
  vpc_zone_identifier  = ["${aws_subnet.private.*.id}"]
  min_size             = 1
  max_size             = 3
  desired_capacity     = 1

  tags = [
    {
      key                 = "Name"
      value               = "${var.environment}-${var.application}-database-asg"
      propagate_at_launch = true
    },
    {
      key                 = "ManagedBy"
      value               = "terraform"
      propagate_at_launch = true
    },
    {
      key                 = "Environment"
      value               = "${var.environment}"
      propagate_at_launch = true
    },
  ]
}

resource "aws_launch_configuration" "ecs_cluster_database" {
  name_prefix          = "${var.environment}-${var.application}-database-ecs-"
  image_id             = "${lookup(var.ecs_amis, var.region)}"
  instance_type        = "${var.ecs_instance_type}"
  key_name             = "${var.key_name}"
  iam_instance_profile = "${aws_iam_instance_profile.ecs_cluster_database.name}"
  security_groups      = ["${aws_security_group.ecs_cluster_group_database.id}", "${aws_security_group.wordpress.id}"]
  user_data            = "#!/bin/bash\necho ECS_CLUSTER=${aws_ecs_cluster.ecs_cluster_database.name} >> /etc/ecs/ecs.config"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_instance_profile" "ecs_cluster_database" {
  name = "${var.environment}-${var.application}-database-ecs-instance-profile"
  role = "${aws_iam_role.ecs_instance_role_database.name}"
}

data "aws_iam_policy_document" "instance_assume_role_policy_database" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_instance_role_database" {
  name               = "${var.environment}-${var.application}-database-ecs-instance-role"
  assume_role_policy = "${data.aws_iam_policy_document.instance_assume_role_policy_database.json}"
}

resource "aws_iam_role_policy_attachment" "ecs_instance_role_database" {
  role       = "${aws_iam_role.ecs_instance_role_database.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_security_group" "ecs_cluster_group_database" {
  name        = "${var.environment}-${var.application}-database-ecs-cluster-sg"
  description = "Allow all to group"
  vpc_id      = "${aws_vpc.vpc.id}"

  ingress {
    from_port = 0
    to_port   = 65535
    protocol  = "TCP"
    security_groups = [ "${aws_security_group.wordpress.id}" ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name        = "${var.environment}-${var.application}-database-ecs-cluster-sg"
    ManagedBy   = "terraform"
    Environment = "${var.environment}"
  }
}
