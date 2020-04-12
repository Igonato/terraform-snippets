# Create an S3 bucket with web access and credentials for accessing it

# Bucket
# Docs: https://www.terraform.io/docs/providers/aws/r/s3_bucket.html
resource "aws_s3_bucket" "main" {
  # Bucket name
  # Note: bucket names must be DNS-compliant
  bucket = var.domain_name

  # Allow Terraform to destroy the bucket even when it isn't empty.
  # Remove the line if you don't want this to happen
  force_destroy = true
}

# Bucket policy for CloudFront access
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
            "Principal": {
              "AWS": "${aws_cloudfront_origin_access_identity.main.iam_arn}"
            },
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::${aws_s3_bucket.main.id}/*"
        }
    ]
}
POLICY
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
