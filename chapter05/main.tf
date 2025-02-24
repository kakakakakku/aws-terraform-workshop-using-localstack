resource "aws_s3_bucket" "chapter05" {
  bucket = "chapter05-bucket"
}

resource "aws_s3_bucket_notification" "chapter05" {
  bucket = aws_s3_bucket.chapter05.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.chapter05.arn
    events              = ["s3:ObjectCreated:*"]
  }
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "lambda_execution_role" {
  name               = "chapter05-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "archive_file" "chapter05" {
  type        = "zip"
  source_dir  = "${path.module}/function/src"
  output_path = "${path.module}/function/dist/chapter05.zip"
}

resource "aws_lambda_function" "chapter05" {
  function_name    = "chapter05-function"
  handler          = "app.lambda_handler"
  runtime          = "python3.12"
  role             = aws_iam_role.lambda_execution_role.arn
  filename         = "${path.module}/function/dist/chapter05.zip"
  source_code_hash = data.archive_file.chapter05.output_base64sha256
}

resource "aws_lambda_permission" "chapter05" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.chapter05.arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.chapter05.arn
}
