# Lambda che esegue la chiamata al servizio REST esterno
resource "aws_lambda_function" "invoke" {
  function_name    = "${var.project}-invoke"
  filename         = "${path.module}/../dist/invoke.zip"
  source_code_hash = filebase64sha256("${path.module}/../dist/invoke.zip") # rileva modifiche al codice
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
  filename         = "${path.module}/../dist/compensate.zip"
  source_code_hash = filebase64sha256("${path.module}/../dist/compensate.zip") # rileva modifiche al codice
  handler          = "index.handler"
  runtime          = "nodejs20.x"
  role             = aws_iam_role.lambda.arn
}

# State machine Step Functions che orchestra il workflow con compensazione
resource "aws_sfn_state_machine" "workflow" {
  name     = "${var.project}-workflow"
  role_arn = aws_iam_role.sfn.arn

  definition = jsonencode({
    Comment = "Workflow con compensazione applicativa"
    StartAt = "InvokeRestService"
    States = {
      # Stato iniziale: chiama la Lambda invoke
      # In caso di qualsiasi errore, passa a Compensate
      InvokeRestService = {
        Type     = "Task"
        Resource = aws_lambda_function.invoke.arn
        Catch = [{
          ErrorEquals = ["States.ALL"] # intercetta tutti gli errori
          ResultPath  = "$.error"      # salva il dettaglio errore nell'input
          Next        = "Compensate"
        }]
        Next = "Success"
      }
      # Stato di compensazione: esegue il rollback chiamando la Lambda compensate
      Compensate = {
        Type     = "Task"
        Resource = aws_lambda_function.compensate.arn
        Next     = "Failure"
      }
      # Stato finale positivo: il servizio REST ha risposto correttamente
      Success = {
        Type = "Succeed"
      }
      # Stato finale negativo: la compensazione è stata eseguita
      Failure = {
        Type  = "Fail"
        Error = "WorkflowFailed"
        Cause = "REST service failed, compensation executed"
      }
    }
  })
}

# Output: ARN della state machine, utile per avviare esecuzioni via CLI o console
output "state_machine_arn" {
  value = aws_sfn_state_machine.workflow.arn
}
