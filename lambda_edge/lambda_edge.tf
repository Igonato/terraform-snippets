# Create a Node.js Lambda function

variable "function_name" {
  default = "tfFunctionName"
}

provider "aws" {
  # Must be deployed in the us-east-1 region for Lambda@Edge
  alias  = "lambda"
  region = "us-east-1"
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  output_path = "lambda.zip"
  source {
    content  = <<JS
module.exports.handler = async (event, context, callback) => {
  const response = `Hello, World!`;
  callback(null, response);
};
JS
    filename = "index.js"
  }
}

# With file
# data "archive_file" "lambda_zip" {
#   type        = "zip"
#   output_path = "lambda_file.zip"
#   source {
#     content  = file("src/index.js")
#     filename = "index.js"
#   }
# }

# With directories
# data "archive_file" "lambda_zip" {
#   type        = "zip"
#   output_path = "lambda_dir.zip"
#   source_dir  = "src"
# }


resource "aws_iam_role" "lambda" {
  provider = aws.lambda
  name     = "lambda"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": ["lambda.amazonaws.com", "edgelambda.amazonaws.com"]
      },
      "Effect": "Allow"
    }
  ]
}
POLICY
}

resource "aws_iam_policy" "lambda_logging" {
  provider    = aws.lambda
  name        = "lambda_logging"
  path        = "/"
  description = "IAM policy for logging from a lambda"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  provider   = aws.lambda
  role       = aws_iam_role.lambda.name
  policy_arn = aws_iam_policy.lambda_logging.arn
}

resource "aws_lambda_function" "lambda_redirect" {
  provider         = aws.lambda
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  function_name    = var.function_name
  handler          = "index.handler"
  role             = aws_iam_role.lambda.arn
  runtime          = "nodejs12.x"
  publish          = true
  depends_on       = [aws_iam_role_policy_attachment.lambda_logs]
}
