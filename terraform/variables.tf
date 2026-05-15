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