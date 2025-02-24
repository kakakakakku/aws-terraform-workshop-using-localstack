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
  name               = "chapter04-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "archive_file" "chapter04" {
  type        = "zip"
  source_dir  = "${path.module}/function/src"
  output_path = "${path.module}/function/dist/chapter04.zip"
}

resource "aws_lambda_function" "chapter04" {
  function_name    = "chapter04-function"
  handler          = "app.lambda_handler"
  runtime          = "python3.12"
  role             = aws_iam_role.lambda_execution_role.arn
  filename         = "${path.module}/function/dist/chapter04.zip"
  source_code_hash = data.archive_file.chapter04.output_base64sha256
}
