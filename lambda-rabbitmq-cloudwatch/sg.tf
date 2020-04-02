resource "aws_security_group" "rabbitmq_to_cloudwatch_sg" {
  name        = "${var.prefix}-sg"
  description = "SG for Lambda function to send RabbitMQ metrics to CloudWatch"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.prefix}-sg"
  }
}

