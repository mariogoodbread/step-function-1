# Trust policy: permette al servizio Lambda di assumere un ruolo IAM
data "aws_iam_policy_document" "lambda_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

# Ruolo IAM assegnato alle funzioni Lambda
resource "aws_iam_role" "lambda" {
  name               = "${var.project}-lambda"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

# Attacca la policy managed AWS che permette a Lambda di scrivere log su CloudWatch
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Trust policy: permette al servizio Step Functions di assumere un ruolo IAM
data "aws_iam_policy_document" "sfn_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["states.amazonaws.com"]
    }
  }
}

# Ruolo IAM assegnato alla state machine Step Functions
resource "aws_iam_role" "sfn" {
  name               = "${var.project}-sfn"
  assume_role_policy = data.aws_iam_policy_document.sfn_assume.json
}

# Policy inline: limita Step Functions a invocare solo le due Lambda del progetto
data "aws_iam_policy_document" "sfn_invoke_lambda" {
  statement {
    actions   = ["lambda:InvokeFunction"]
    resources = [
      aws_lambda_function.invoke.arn,     # Lambda che chiama il servizio REST
      aws_lambda_function.compensate.arn, # Lambda di compensazione in caso di errore
    ]
  }
}

# Attacca la policy inline al ruolo di Step Functions
resource "aws_iam_role_policy" "sfn_invoke_lambda" {
  name = "${var.project}-sfn-invoke-lambda"
  role   = aws_iam_role.sfn.id
  policy = data.aws_iam_policy_document.sfn_invoke_lambda.json
}
