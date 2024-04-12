terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.29"
    }
  }

  required_version = ">= 1.4.5"

  backend "s3" {
    bucket = "sen-learning-tfstate"
    key    = "sen-learning-tfstate"
    region = "us-east-1"
  }
}

resource "aws_dynamodb_table" "sen_learning_dynamodb" {
  name         = "sen-learning-dynamodb"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "catname"
  range_key    = "lastfed"
  attribute {
    name = "catname"
    type = "S"
  }
  attribute {
    name = "lastfed"
    type = "N"
  }

}

module "lambda_bucket" {
  source = "./terraform/s3_bucket"
  bucket_name = "sen-learning-lambda"
  
}

data "archive_file" "feedcat" {
  type        = "zip"
  source_dir  = "${path.module}/feedcat/dist"
  output_path = "${path.module}/build/feedcat.zip"

}

resource "aws_s3_object" "feedcat" {
  bucket = module.lambda_bucket.bucket_id
  key    = "feedcat.zip"
  source = data.archive_file.feedcat.output_path
  etag = data.archive_file.feedcat.output_md5

}

resource "aws_iam_role" "lambda" {
  name = "sen-learning-lambda-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      },
    ]
  })
}
resource "aws_iam_role_policy_attachment" "feedcat" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"

}
resource "aws_lambda_function" "feedcat" {
  function_name = "feedcat"
  s3_bucket     = module.lambda_bucket.bucket_id
  s3_key        = aws_s3_object.feedcat.key
  handler       = "handler.run"
  runtime       = "nodejs16.x"
  role          = aws_iam_role.lambda.arn
  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.sen_learning_dynamodb.name
    }
  }

}
resource "aws_apigatewayv2_api" "feedcat" {
  name          = "feedcat"
  protocol_type = "HTTP"
  target        = aws_lambda_function.feedcat.invoke_arn

}

resource "aws_apigatewayv2_stage" "feedcat" {
  api_id      = aws_apigatewayv2_api.feedcat.id
  name        = "v1"
  auto_deploy = true

}

resource "aws_apigatewayv2_integration" "feedcat" {
  api_id             = aws_apigatewayv2_api.feedcat.id
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
  integration_uri    = aws_lambda_function.feedcat.invoke_arn


}

resource "aws_apigatewayv2_route" "feedcat" {
  api_id    = aws_apigatewayv2_api.feedcat.id
  route_key = "POST /cat"
  target    = "integrations/${aws_apigatewayv2_integration.feedcat.id}"

}

resource "aws_lambda_permission" "feedcat" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.feedcat.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.feedcat.execution_arn}/*/*"

}

resource "aws_iam_policy" "dbwrite" {
  name        = "sen-learning-dynamodb-write"
  description = "Allow write to feedcat dynamodb"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem"
        ]
        Resource = aws_dynamodb_table.sen_learning_dynamodb.arn
      },
    ]
  })

}

resource "aws_iam_role_policy_attachment" "feed_cats_dbwrite" {
  role       = aws_iam_role.lambda.name
  policy_arn = aws_iam_policy.dbwrite.arn

}

