# Create an S3 bucket with web access and credentials for accessing it

# Using AWS provider
# Docs: https://www.terraform.io/docs/providers/aws/
provider "aws" {
    # Optional. If isn't specified Terraform will ask during apply.
    # You can set AWS_DEFAULT_REGION environment variable instead
    # region = "eu-central-1"
}

# Bucket
# Docs: https://www.terraform.io/docs/providers/aws/r/s3_bucket.html
resource "aws_s3_bucket" "main" {
    # Bucket name
    # Note: bucket names must be DNS-compliant
    # Specifying `bucket_prefix` avoids name collisions
    bucket_prefix = "tf-"
    # To specify a full name instead use `bucket`:
    # bucket = "my-bucket-123"

    # Allow Terraform to destroy the bucket even when it isn't empty.
    # Remove the line if you don't want this to happen
    force_destroy = true

    # Web access (also, see aws_s3_bucket_policy below)
    acl = "public-read"
    website {
        index_document = "index.html"
        # error_document = "error.html"
    }
}

# Bucket policy for web access
# Docs: https://www.terraform.io/docs/providers/aws/r/s3_bucket_policy.html
resource "aws_s3_bucket_policy" "main" {
    bucket = aws_s3_bucket.main.id
    policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicReadForGetBucketObjects",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::${aws_s3_bucket.main.id}/*"
        }
    ]
}
POLICY
}

# Test index.html file to see if it works
# Docs: https://www.terraform.io/docs/providers/aws/r/s3_bucket_object.html
resource "aws_s3_bucket_object" "test" {
    bucket       = aws_s3_bucket.main.id
    key          = "index.html"
    content_type = "text/html"
    content      = <<HTML
<!DOCTYPE html>
<html>
<head>
    <title>It works!</title>
</head>
<body>
    It works!
</body>
</html>
HTML
}

# User that should be able to write to the bucket
# Docs: https://www.terraform.io/docs/providers/aws/r/iam_user.html
resource "aws_iam_user" "s3_user" {
    name = "s3-bucket-user-${aws_s3_bucket.main.id}"
}

# Access credentials
# Docs: https://www.terraform.io/docs/providers/aws/r/iam_access_key.html
resource "aws_iam_access_key" "s3_user" {
    user = aws_iam_user.s3_user.name
}

# User policy to let the user access the bucket
# Docs: https://www.terraform.io/docs/providers/aws/r/iam_user_policy.html
resource "aws_iam_user_policy" "s3_user" {
    name   = "s3-bucket-access-${aws_s3_bucket.main.id}"
    user   = aws_iam_user.s3_user.name
    policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "s3:*",
            "Resource": [
                "arn:aws:s3:::${aws_s3_bucket.main.id}",
                "arn:aws:s3:::${aws_s3_bucket.main.id}/*"
            ]
        }
    ]
}
POLICY
}

# Outputs
output "bucket_name" {
    value = aws_s3_bucket.main.id
}

output "bucket_website_endpoint" {
    value = "http://${aws_s3_bucket.main.website_endpoint}"
}

output "bucket_domain" {
    # Notice that https can be used there unlike with the website
    # although you don't get to the index.html when accessing the root
    # For hosting a website with ssl you should add CloudFront to the mix
    value = "https://${aws_s3_bucket.main.bucket_domain_name}/index.html"
}

# Keep credentials secret
output "aws_access_key_id" {
    value = aws_iam_access_key.s3_user.id
}

output "aws_secret_access_key" {
    value = aws_iam_access_key.s3_user.secret
}
