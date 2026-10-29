variable "aws_region" {
  description = "AWS region for all regional resources"
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  type    = string
  default = "devops-assessment"
}

variable "environment" {
  type    = string
  default = "assessment"
}

variable "vpc_cidr" {
  type    = string
  default = "10.30.0.0/16"
}

variable "instance_type" {
  description = "Choose a small instance type available in the selected region"
  type        = string
  default     = "t3.micro"
}

variable "db_instance_class" {
  description = "Small RDS class; verify availability and pricing in ap-south-1"
  type        = string
  default     = "db.t3.micro"
}

variable "db_name" {
  type    = string
  default = "assessmentdb"
}

variable "db_username" {
  type    = string
  default = "appadmin"
}

variable "certificate_arn" {
  description = "Optional ACM certificate ARN in the same region as the ALB. Leave empty for HTTP-only testing."
  type        = string
  default     = ""
}

variable "desired_capacity" {
  type    = number
  default = 2
}

variable "min_size" {
  type    = number
  default = 2
}

variable "max_size" {
  type    = number
  default = 2
}
