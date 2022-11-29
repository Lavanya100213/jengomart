variable "region" {
  type        = string
  description = "Target region"
}

variable "account" {
  type        = number
  description = "Target AWS account number"
}

variable "env" {
  type        = string
  description = "Environment name"
}

variable "number_of_azs" {
  type        = number
  description = "Number of azs to deploy to"
  default     = 2
}