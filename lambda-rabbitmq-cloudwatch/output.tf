output "arn" {
  value = aws_lambda_function.rabbitmq_to_cloudwatch.arn
}

output "name" {
  value = aws_lambda_function.rabbitmq_to_cloudwatch.function_name
}

output "sg" {
  value = aws_security_group.rabbitmq_to_cloudwatch_sg.id
}

