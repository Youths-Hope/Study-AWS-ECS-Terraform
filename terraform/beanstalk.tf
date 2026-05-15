resource "aws_elastic_beanstalk_application" "study_app" {
  name        = "study-app-tf"
  description = "Study Node.js Application by Terraform"
}

resource "aws_elastic_beanstalk_environment" "study_env" {
  name                = "study-env-tf"
  application         = aws_elastic_beanstalk_application.study_app.name
  solution_stack_name = "64bit Amazon Linux 2023 v6.10.3 running Node.js 20"

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.beanstalk_instance_profile.name
  }

  depends_on = [
    aws_iam_instance_profile.beanstalk_instance_profile
  ]
}