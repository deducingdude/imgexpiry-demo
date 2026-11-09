provider "aws" {
  region  = var.region
  profile = var.profile

  default_tags {
    tags = {
      project = "imgexpiry-demo"
    }
  }
}

resource "aws_ecr_repository" "demo" {
  name                 = var.repository_name
  image_tag_mutability = "MUTABLE"

  # Lets `tofu destroy` remove the repository even if it still holds images.
  force_delete = true
}

# Same policy as imgexpiry's fixtures/lifecycle-policy.json, so the tool and
# AWS's lifecycle preview are tested against identical rules.
resource "aws_ecr_lifecycle_policy" "demo" {
  repository = aws_ecr_repository.demo.name
  policy     = file("${path.module}/lifecycle-policy.json")
}
