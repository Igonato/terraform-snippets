# Lambda function for default index and www. redirect

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
exports.handler = (event, context, callback) => {
  let request = event.Records[0].cf.request;
  if (request.headers.host[0].value === 'www.${var.domain_name}') {
    request.uri = request.uri.replace(/\/index.html$/, '\/');
    return callback(null, {
      status: '301',
      statusDescription: `Redirect to apex domain`,
      headers: {
        location: [{
          key: 'Location',
          value: `https://${var.domain_name}$${request.uri}`
        }]
      }
    });
  }
  request.headers.host[0].value = '${var.domain_name}.s3.amazonaws.com';
  request.uri = request.uri.replace(/\/$/, '\/index.html');
  return callback(null, request);
};
JS
    filename = "index.js"
  }
}

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
  function_name    = "directoryIndexAndWWWRedirect"
  handler          = "index.handler"
  role             = aws_iam_role.lambda.arn
  runtime          = "nodejs12.x"
  publish          = true
  depends_on       = [aws_iam_role_policy_attachment.lambda_logs]
}
