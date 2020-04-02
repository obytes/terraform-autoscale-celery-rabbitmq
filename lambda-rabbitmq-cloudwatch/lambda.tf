data "archive_file" "lambda_zip" {
  type        = "zip"
  output_path = "${path.module}/sources/.zip/main.zip"

  source {
    filename = "main.py"
    content  = file("${path.module}/sources/main.py")
  }
}

resource "aws_lambda_function" "rabbitmq_to_cloudwatch" {
  function_name = var.prefix
  role          = aws_iam_role.lambda_ecs.arn
  handler       = var.handler
  runtime       = var.runtime

  # package
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  publish          = "true"

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [aws_security_group.rabbitmq_to_cloudwatch_sg.id]
  }

  environment {
    variables = var.secrets
  }
}

