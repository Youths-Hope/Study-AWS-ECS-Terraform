resource "aws_ecr_repository" "study_node_app" {
  name = "study-node-app"

  image_scanning_configuration {
    scan_on_push = true
  }

  image_tag_mutability = "MUTABLE"
}