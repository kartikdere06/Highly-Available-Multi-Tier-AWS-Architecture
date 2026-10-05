# ---------------------------------------------------------------------------
# Database tier: Multi-AZ MySQL in the isolated DB subnets.
# The master password is generated and stored by RDS in Secrets Manager, so it
# never appears in Terraform code or in plain text in the state file.
# ---------------------------------------------------------------------------

resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnets"
  subnet_ids = aws_subnet.db[*].id

  tags = { Name = "${var.project_name}-db-subnets" }
}

resource "aws_db_instance" "main" {
  identifier        = "${var.project_name}-db"
  engine            = "mysql"
  engine_version    = "8.0"
  instance_class    = var.db_instance_class
  allocated_storage = 20
  storage_type      = "gp3"
  storage_encrypted = true

  db_name  = var.db_name
  username = var.db_username

  manage_master_user_password = true

  multi_az               = true
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.db.id]
  publicly_accessible    = false

  backup_retention_period = 7
  backup_window           = "21:00-22:00"
  maintenance_window      = "sun:22:30-sun:23:30"

  auto_minor_version_upgrade = true
  deletion_protection        = var.environment == "prod"
  skip_final_snapshot        = var.environment != "prod"
  final_snapshot_identifier  = var.environment == "prod" ? "${var.project_name}-final" : null

  tags = { Name = "${var.project_name}-db" }
}
