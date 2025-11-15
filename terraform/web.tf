resource "aws_acm_certificate" "web" {
  domain_name = "daan.se"
  validation_method = "DNS"
  provider = aws.us-east-1
  tags = local.default-tags
}

resource "aws_acm_certificate_validation" "web" {
  certificate_arn         = aws_acm_certificate.web.arn
  validation_record_fqdns = [for record in aws_route53_record.web-validation : record.fqdn]
  provider = aws.us-east-1
}

resource "aws_route53_record" "web-validation" {
  for_each = {
    for dvo in aws_acm_certificate.web.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = aws_route53_zone.daan-se.zone_id
}

resource "aws_cloudfront_distribution" "web" {
  enabled = true

  origin {
    domain_name = aws_s3_bucket.web.bucket_regional_domain_name
    origin_id   = aws_s3_bucket.web.bucket
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.web.cloudfront_access_identity_path
    }
  }

  default_root_object = "index.html"

  aliases = [ "daan.se" ]

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  price_class = "PriceClass_100"

  viewer_certificate {
    minimum_protocol_version = "TLSv1.2_2021"
    acm_certificate_arn = aws_acm_certificate_validation.web.certificate_arn
    ssl_support_method = "sni-only"
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = aws_s3_bucket.web.bucket
    viewer_protocol_policy = "https-only"
    cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6"
    compress = true
  }
  tags = local.default-tags
}

resource "aws_cloudfront_origin_access_identity" "web" {
  comment = "daan-se-web"
}

resource "aws_s3_bucket" "web" {
  bucket = "daan-se-web"
  tags = local.default-tags
}

resource "aws_s3_bucket_public_access_block" "web" {
  bucket = aws_s3_bucket.web.id
  block_public_acls   = true
  block_public_policy = true
  ignore_public_acls = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "web" {
  bucket = aws_s3_bucket.web.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_object" web {
  bucket = aws_s3_bucket.web.id
  for_each = fileset("web", "*")
  key = each.key
  source = "web/${each.key}"
  content_type = lookup(local.mime_types, element(split(".", each.key), length(split(".", each.key)) - 1))
  etag = filemd5("web/${each.key}")
  tags = local.default-tags
}

resource "aws_s3_bucket_policy" "web" {
  bucket = aws_s3_bucket.web.bucket
  policy = jsonencode({
    "Version": "2008-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "AWS":  aws_cloudfront_origin_access_identity.web.iam_arn
        },
        "Action": "s3:GetObject",
        "Resource": "${aws_s3_bucket.web.arn}/*"
      }
    ]
  })
}

resource "aws_route53_record" "web" {
  zone_id = aws_route53_zone.daan-se.zone_id
  for_each = {
    for a in aws_cloudfront_distribution.web.aliases : a => {}
  }
  name    = each.key
  type    = "A"
  alias {
    evaluate_target_health = true
    name = aws_cloudfront_distribution.web.domain_name
    zone_id = aws_cloudfront_distribution.web.hosted_zone_id
  }
}

locals {
  mime_types = {
    "css"  = "text/css"
    "html" = "text/html"
    "ico"  = "image/vnd.microsoft.icon"
    "js"   = "application/javascript"
    "json" = "application/json"
    "map"  = "application/json"
    "png"  = "image/png"
    "svg"  = "image/svg+xml"
    "txt"  = "text/plain"
  }
}
