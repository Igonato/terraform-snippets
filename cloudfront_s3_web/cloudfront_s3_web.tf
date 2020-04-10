# Create a cloudfront distribution for serving static content from an S3 bucket

variable "domain_name" {
  # default = "example.com"
}

provider "aws" {
  region = "eu-central-1"
}

data "aws_route53_zone" "main" {
  name         = "${var.domain_name}."
  private_zone = false
}


resource "aws_cloudfront_origin_access_identity" "main" {
  comment = "Access for CloudFront"
}

resource "aws_cloudfront_distribution" "distribution" {
  origin {
    domain_name = aws_s3_bucket.main.bucket_domain_name
    origin_id   = "${var.domain_name}-origin"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.main.cloudfront_access_identity_path
    }
  }

  aliases             = [var.domain_name, "www.${var.domain_name}"]
  enabled             = "true"
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "${var.domain_name}-origin"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate_validation.main.certificate_arn
    ssl_support_method  = "sni-only"
    minimum_protocol_version = "TLSv1.1_2016"
  }

  custom_error_response {
    error_code            = "404"
    response_code         = "404"
    response_page_path    = "/404.html"
    error_caching_min_ttl = "1800"
  }
}

# Bare domain
resource "aws_route53_record" "domain" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.distribution.domain_name
    zone_id                = aws_cloudfront_distribution.distribution.hosted_zone_id
    evaluate_target_health = false
  }
}

# WWW domain
resource "aws_route53_record" "www-domain" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "www.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.distribution.domain_name
    zone_id                = aws_cloudfront_distribution.distribution.hosted_zone_id
    evaluate_target_health = false
  }
}

# Bucket access for uplodaing
output "aws_access_key_id" {
  value = aws_iam_access_key.s3_user.id
}

output "aws_secret_access_key" {
  value = aws_iam_access_key.s3_user.secret
}

output "bucket_id" {
  value = aws_s3_bucket.main.id
}
