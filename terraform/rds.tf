resource "aws_db_subnet_group" "study_db_subnet" {
  name = "study-db-subnet"
  description = "for study"

  subnet_ids = [
    var.subnet_id_1,
    var.subnet_id_2
  ]
}

resource "aws_db_instance" "study_db" {
  identifier = "study-db-ecs"

  engine         = "mysql"
  engine_version = "8.4.8"

  instance_class = "db.t4g.micro"

  allocated_storage     = 20
  max_allocated_storage = 1000
  storage_type          = "gp2"
  storage_encrypted     = true

  username = "admin"
  password = var.db_password

  publicly_accessible = false
  skip_final_snapshot = true

  copy_tags_to_snapshot = true

  vpc_security_group_ids = [
    aws_security_group.study_rds_sg.id
  ]

  db_subnet_group_name = aws_db_subnet_group.study_db_subnet.name
}