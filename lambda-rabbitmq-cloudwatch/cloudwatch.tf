resource "aws_cloudwatch_log_group" "cw_log" {
  name       = "/aws/lambda/${var.prefix}"
  kms_key_id = var.kms_arn
}

