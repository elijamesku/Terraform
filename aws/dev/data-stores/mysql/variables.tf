variable "aws_region" {
  type    = string
  default = "us-east-2"
}

variable "allowed_cidr" {
  type    = string
  default = "0.0.0.0/0"

}

variable "db_username" {
  type        = string
  default     = "devuser"
  description = "Master username (1-16 chars, start with a letter)"
  validation {
    condition     = can(regex("^[A-Za-z][A-Za-z0-9_]{0,15}$", var.db_username))
    error_message = "Must start with a letter; only letters, digits, underscore; max 16 chars"
  }
}

variable "db_name" {
  type    = string
  default = "sql_db"

}