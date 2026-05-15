resource "aws_security_group" "study_db_sg" {
  name        = "study-db-sg-tf"
  description = "Security group for study RDS"
  vpc_id      = var.vpc_id

  ingress {
    description = "MySQL access for study"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"

    # 学習用。一時的に全開。
    # 後で Beanstalk SG のみに変更する。
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_subnet_group" "study_db_subnet" {
  name        = "study-db-subnet-tf"
  description = "DB subnet group for study RDS"

  subnet_ids = [
    var.subnet_id_1,
    var.subnet_id_2
  ]
}

resource "aws_db_instance" "study_db" {
  identifier             = "study-db-tf"
  instance_class         = "db.t3.micro"
  engine                 = "mysql"
  engine_version         = "8.0"
  allocated_storage      = 20
  storage_type           = "gp2"

  username               = "admin"
  password               = var.db_password
  db_name                = "study_db"

  vpc_security_group_ids = [aws_security_group.study_db_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.study_db_subnet.name

  publicly_accessible    = true
  multi_az               = false
  backup_retention_period = 0
  deletion_protection    = false
  skip_final_snapshot    = true
}