variable "prefix" {
}

variable "common_tags" {
  type = map(string)
}

variable "handler" {
  default = "main.lambda_handler"
}

variable "runtime" {
  default = "python3.6"
}

variable "kms_arn" {
}

variable "vpc_id" {
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "secrets" {
  type = map(string)
}

