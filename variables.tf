variable "access_key" {}
variable "secret_key" {}
variable "aws_pem" {}
variable "instance_count" {
  default = 1
  }
variable "json_location" {
  default = "application-install/settings.json"
  }
variable "replicated_conf" {
  default = "application-install/replicated.conf"
  }
variable "license" {
  default = "application-install/amy.rli"
  }
