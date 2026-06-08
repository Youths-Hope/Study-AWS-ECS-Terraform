resource "aws_sns_topic" "alarm_topic" {
  name = "study-alarm-topic"
}

resource "aws_sns_topic_subscription" "alarm_email" {
  topic_arn = aws_sns_topic.alarm_topic.arn

  protocol = "email"

  endpoint = "youthin@gmail.com"
}