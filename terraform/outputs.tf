output "rds_endpoint" {
  value = aws_db_instance.study_db.address
}

output "rds_security_group_id" {
  value = aws_security_group.study_db_sg.id
}

output "beanstalk_app_name" {
  value = aws_elastic_beanstalk_application.study_app.name
}

output "beanstalk_env_name" {
  value = aws_elastic_beanstalk_environment.study_env.name
}

output "beanstalk_cname" {
  value = aws_elastic_beanstalk_environment.study_env.cname
}