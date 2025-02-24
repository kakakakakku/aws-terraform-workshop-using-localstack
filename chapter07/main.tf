import {
  to = aws_cloudwatch_log_group.chapter07
  id = "chapter07-logs"
}

resource "aws_cloudwatch_log_group" "chapter07" {
  name = "chapter07-logs"
}
