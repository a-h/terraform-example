resource "aws_rds_cluster" "aurora_cluster" {
  engine                       = "aurora"
  cluster_identifier           = "${var.environment}-${var.application}-aurora"
  database_name                = "${var.master_database}"
  master_username              = "${var.master_username}"
  master_password              = "${var.master_password}"
  backup_retention_period      = 1
  preferred_backup_window      = "02:00-03:00"
  preferred_maintenance_window = "wed:03:00-wed:04:00"
  db_subnet_group_name         = "${aws_db_subnet_group.aurora_subnet_group.name}"
  final_snapshot_identifier    = "${var.environment}-${var.application}-aurora"
  storage_encrypted            = true

  vpc_security_group_ids = ["${aws_security_group.ecs_cluster_group_database.id}"]

  tags {
    Name        = "${var.environment}-${var.application}-aurora"
    ManagedBy   = "terraform"
    Environment = "${var.environment}"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_rds_cluster_instance" "aurora_cluster_instance" {
  count = "${length(var.private_subnet_ranges)}"

  identifier           = "${var.environment}-${var.application}-aurora-instance-${count.index}"
  cluster_identifier   = "${aws_rds_cluster.aurora_cluster.id}"
  instance_class       = "${var.aurora_instance_type}"
  db_subnet_group_name = "${aws_db_subnet_group.aurora_subnet_group.name}"
  publicly_accessible  = false

  tags {
    Name        = "${var.environment}-${var.application}-aurora-instance-${count.index}"
    ManagedBy   = "terraform"
    Environment = "${var.environment}"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_db_subnet_group" "aurora_subnet_group" {
  name        = "${var.environment}-${var.application}-db-subnet-group"
  description = "Allowed subnets for Aurora DB cluster instances"
  subnet_ids  = ["${aws_subnet.private.*.id}"]

  tags {
    Name        = "${var.environment}-${var.application}-aurora-subnet-group"
    ManagedBy   = "terraform"
    Environment = "${var.environment}"
  }
}

output "cluster_endpoint" {
  value = "${aws_rds_cluster.aurora_cluster.endpoint}"
}

output "cluster_port" {
  value = "${aws_rds_cluster.aurora_cluster.port}"
}
