# Create and validate an ACM certificate for domain and www.domain

provider "aws" {
  # If you're planning on importing the certificate in CloudFront
  # the region has to be "us-east-1"
  alias  = "useast1"
  region = "us-east-1"
}

resource "aws_acm_certificate" "main" {
  provider = aws.useast1
  domain_name               = var.domain_name
  subject_alternative_names = ["www.${var.domain_name}"]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cert_validation" {
  name    = aws_acm_certificate.main.domain_validation_options.0.resource_record_name
  type    = aws_acm_certificate.main.domain_validation_options.0.resource_record_type
  zone_id = data.aws_route53_zone.main.id
  records = [aws_acm_certificate.main.domain_validation_options.0.resource_record_value]
  ttl     = 60
}

resource "aws_route53_record" "cert_validation_alt" {
  name    = aws_acm_certificate.main.domain_validation_options.1.resource_record_name
  type    = aws_acm_certificate.main.domain_validation_options.1.resource_record_type
  zone_id = data.aws_route53_zone.main.id
  records = [aws_acm_certificate.main.domain_validation_options.1.resource_record_value]
  ttl     = 60
}

resource "aws_acm_certificate_validation" "main" {
  provider = aws.useast1
  certificate_arn = aws_acm_certificate.main.arn

  validation_record_fqdns = [
    aws_route53_record.cert_validation.fqdn,
    aws_route53_record.cert_validation_alt.fqdn,
  ]
}
