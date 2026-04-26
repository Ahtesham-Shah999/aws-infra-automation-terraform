variable "region" {
  default = "us-east-1"
}
variable "key_name" {
  default = "devops-a3-key"
}
variable "my_ip" {
  description = "Your IP with /32 CIDR"
  type        = string
}
