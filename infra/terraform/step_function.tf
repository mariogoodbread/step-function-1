# Lambda che esegue la chiamata al servizio REST esterno
resource "aws_lambda_function" "invoke" {
  function_name    = "${var.project}-invoke"
  filename         = "${path.root}/../../dist/invoke.zip"
  source_code_hash = filebase64sha256("${path.root}/../../dist/invoke.zip") # rileva modifiche al codice
  handler          = "index.handler"
  runtime          = "nodejs20.x"
  role             = aws_iam_role.lambda.arn

  environment {
    variables = {
      REST_URL = var.rest_url
    }
  }
}

# Lambda che esegue la compensazione applicativa in caso di errore
resource "aws_lambda_function" "compensate" {
  function_name    = "${var.project}-compensate"
  filename         = "${path.root}/../../dist/compensate.zip"
  source_code_hash = filebase64sha256("${path.root}/../../dist/compensate.zip") # rileva modifiche al codice
  handler          = "index.handler"
  runtime          = "nodejs20.x"
  role             = aws_iam_role.lambda.arn
}

module "step_functions" {
  source  = "terraform-aws-modules/step-functions/aws"
  version = "~> 4.0"

  name = "${var.project}-workflow"

  definition = jsonencode({
    Comment = "Workflow con compensazione applicativa"
    StartAt = "InvokeRestService"
    States = {
      InvokeRestService = {
        Type     = "Task"
        Resource = aws_lambda_function.invoke.arn
        Catch = [{
          ErrorEquals = ["States.ALL"]
          ResultPath  = "$.error"
          Next        = "Compensate"
        }]
        Next = "Success"
      }
      Compensate = {
        Type     = "Task"
        Resource = aws_lambda_function.compensate.arn
        Next     = "Failure"
      }
      Success = {
        Type = "Succeed"
      }
      Failure = {
        Type  = "Fail"
        Error = "WorkflowFailed"
        Cause = "REST service failed, compensation executed"
      }
    }
  })

  attach_policy_statements = true
  policy_statements = {
    lambda = {
      effect    = "Allow"
      actions   = ["lambda:InvokeFunction"]
      resources = [
        aws_lambda_function.invoke.arn,
        aws_lambda_function.compensate.arn,
      ]
    }
  }
}

output "state_machine_arn" {
  value = module.step_functions.state_machine_arn
}
