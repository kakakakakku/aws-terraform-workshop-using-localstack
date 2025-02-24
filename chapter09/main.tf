resource "aws_s3_bucket" "chapter09" {
  bucket = "chapter09-bucket"
}

resource "aws_cloudwatch_log_group" "chapter09" {
  name              = "chapter09-logs"
  retention_in_days = 7
}
