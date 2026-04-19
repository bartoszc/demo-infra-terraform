terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = "eu-central-1"
}

resource "aws_s3_bucket" "demo" {
  bucket = "my-demo-bucket-oz-test"
  acl    = "public-read"
}
