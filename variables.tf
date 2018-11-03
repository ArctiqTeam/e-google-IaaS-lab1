variable "project" {
  default = "workshop-209"
}

variable "region" {
  default = "us-east1"
}

variable "zones" {
  default = ["us-east1-b", "us-east1-d", "us-east1-c"]
}

variable "server_count" {
  description = "How many do we build, boss?"
  default     = 3
}
