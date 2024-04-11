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

resource "aws_dynamodb_table" "sen-learning-dynamodb" {
  name           = "sen-learning-dynamodb"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "catname"
  range_key      = "lastfed"
  attribute {
    name = "catname"
    type = "S"
  }
  attribute {
    name = "lastfed"
    type = "N"
  }
  
}
