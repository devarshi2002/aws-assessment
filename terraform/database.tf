resource "aws_db_subnet_group" "db" {
  name       = "${var.project_name}-db-subnets"
  subnet_ids = aws_subnet.database[*].id
  tags       = { Name = "${var.project_name}-db-subnets" }
}

resource "aws_db_instance" "mysql" {
  identifier                      = "${var.project_name}-mysql"
  engine                          = "mysql"
  engine_version                  = "8.0"
  instance_class                  = var.db_instance_class
  allocated_storage               = 20
  max_allocated_storage           = 20
  storage_type                    = "gp3"
  storage_encrypted               = true
  db_name                         = var.db_name
  username                        = var.db_username
  password                        = random_password.db.result
  port                            = 3306
  db_subnet_group_name            = aws_db_subnet_group.db.name
  vpc_security_group_ids          = [aws_security_group.db.id]
  publicly_accessible             = false
  multi_az                        = false
  backup_retention_period         = 0
  deletion_protection             = false
  skip_final_snapshot             = true
  auto_minor_version_upgrade      = true
  apply_immediately               = true
  enabled_cloudwatch_logs_exports = ["error"]
  tags                            = { Name = "${var.project_name}-mysql" }
}
