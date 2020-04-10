# Create a hosted zone and ouput nameservers

variable "domain_name" {
  # default = "example.com"
}

provider "aws" {
  # Optional. If isn't specified Terraform will ask during apply.
  # You can set AWS_DEFAULT_REGION environment variable instead
  # region = "eu-central-1"
}

resource "aws_route53_zone" "main" {
  name = var.domain_name
}

output "bucket_website_endpoint" {
  value = aws_route53_zone.main.name_servers
}
