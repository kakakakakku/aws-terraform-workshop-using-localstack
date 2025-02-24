variable "retention_in_days" {
  type    = number
  default = 365
}

resource "aws_cloudwatch_log_group" "chapter08-test" {
  name              = "chapter08+logs"
  retention_in_days = 7
}
