variable "vpc_id" {
  type = string
}

variable "subnet_id_1" {
  type = string
}

variable "subnet_id_2" {
  type = string
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "container_name" {
  type = string
}

variable "app_port" {
  type = number
}

variable "db_name" {
  type = string
}

variable "db_user" {
  type = string
}

variable "s3_bucket_name" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "service_name" {
  type = string
}

variable "task_family" {
  type = string
}