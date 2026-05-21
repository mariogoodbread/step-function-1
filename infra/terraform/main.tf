# Configurazione Terraform: specifica il provider AWS richiesto con versione minima 5.x
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Inizializza il provider AWS nella regione definita dalla variabile aws_region
provider "aws" {
  region = var.aws_region
}
