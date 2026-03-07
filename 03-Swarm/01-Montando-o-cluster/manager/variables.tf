variable "aws_region" {
  description = "The AWS region to create things in."
  default     = "us-east-1"
}

variable "ami_ssm_parameter" {
  description = "Public SSM parameter for the latest Amazon Linux AMI"
  default     = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

variable "KEY_NAME" {
  default = "vockey"
}
variable "PATH_TO_KEY" {
  default = "/home/ubuntu/.ssh/vockey.pem"
}
variable "INSTANCE_USERNAME" {
  default = "ec2-user"
}
