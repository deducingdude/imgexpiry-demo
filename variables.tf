variable "region" {
  type    = string
  default = "us-west-2"
}

variable "profile" {
  description = "AWS SSO profile; run `aws sso login --profile <profile>` first."
  type        = string
  default     = "imgexpiry"
}

variable "repository_name" {
  type    = string
  default = "imgexpiry-demo"
}
