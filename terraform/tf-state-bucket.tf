locals {
  projects = [
    "daan-se",
    "budgetd",
    "tea",
    "flight"
  ]
}

resource "aws_s3_bucket" "tf-state" {
  for_each = toset(local.projects)
  bucket = "${each.key}-tf-state"
  tags = {
    application: each.key
  }
}

resource "aws_s3_bucket_public_access_block" "tf-state" {
  for_each = toset(local.projects)
  bucket = aws_s3_bucket.tf-state[each.key].id
  block_public_acls   = true
  block_public_policy = true
  ignore_public_acls = true
  restrict_public_buckets = true
}