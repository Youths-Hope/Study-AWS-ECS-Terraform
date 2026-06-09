resource "aws_secretsmanager_secret" "db_password" {
  name = "study/db/password"

  recovery_window_in_days        = 30
  force_overwrite_replica_secret = false
}

resource "aws_secretsmanager_secret" "db_user" {
  name = "study/db/user"
}