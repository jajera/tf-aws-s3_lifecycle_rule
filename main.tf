variable "use_case" {
  default = "tf-aws-s3_lifecycle_rule"
}

resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

resource "aws_resourcegroups_group" "example" {
  name        = "tf-rg-example-${random_string.suffix.result}"
  description = "Resource group for example resources"

  resource_query {
    query = <<JSON
    {
      "ResourceTypeFilters": [
        "AWS::AllSupported"
      ],
      "TagFilters": [
        {
          "Key": "Owner",
          "Values": ["John Ajera"]
        },
        {
          "Key": "UseCase",
          "Values": ["${var.use_case}"]
        }
      ]
    }
    JSON
  }

  tags = {
    Name    = "tf-rg-example-${random_string.suffix.result}"
    Owner   = "John Ajera"
    UseCase = var.use_case
  }
}

resource "aws_s3_bucket" "example" {
  bucket        = "tf-s3-example-${random_string.suffix.result}"
  force_destroy = true

  tags = {
    Name    = "tf-s3-example-${random_string.suffix.result}"
    Owner   = "John Ajera"
    UseCase = var.use_case
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "example" {
  bucket = aws_s3_bucket.example.id

  rule {
    id     = "move-to-glacier"
    filter {
      and {
        prefix = "documents/"

        tags = {
          rule      = "documents"
          autoclean = "true"
        }
      }
    }
    status  = "Enabled"

    transition {
      days          = 30
      storage_class = "GLACIER"
    }
  }

  rule {
    id     = "delete-old-logs"
    filter {
      and {
        prefix = "logs/"

        tags = {
          rule      = "logs"
          autoclean = "true"
        }
      }
    }
    status = "Enabled"

    expiration {
      date = "2030-01-01T00:00:00Z"
    }
  }

  rule {
    id     = "archive-to-cold-storage"
    filter {
      and {
        prefix = "archive/"

        tags = {
          rule      = "archive"
          autoclean = "true"
        }
      }
    }
    status = "Enabled"

    transition {
      days          = 60
      storage_class = "DEEP_ARCHIVE"
    }

    expiration {
      days = 365
    }
  }

  rule {
    id      = "delete-after-7-days"
    status = "Enabled"

    expiration {
      days = 7
    }
  }

  rule {
    id      = "move-to-standard-after-180-days"
    status = "Enabled"

    transition {
      days          = 180
      storage_class = "STANDARD_IA"
    }
  }
}
