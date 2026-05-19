# Regione AWS in cui verranno creati tutte le risorse
variable "aws_region" {
  default = "eu-west-1"
}

# Prefisso usato per nominare tutte le risorse del progetto
variable "project" {
  default = "step-functions1"
}

# URL del servizio REST esterno da invocare
variable "rest_url" {
  default = "https://jsonplaceholder.typicode.com/todos/1"
}
