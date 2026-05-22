module "lambda_invoke" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 7.0"

  function_name = "${var.project}-invoke"
  handler       = "index.handler"
  runtime       = "nodejs20.x"

  create_package         = false
  local_existing_package = "${path.root}/../../dist/invoke.zip"

  environment_variables = {
    REST_URL = var.rest_url
  }
}

module "lambda_compensate" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 7.0"

  function_name = "${var.project}-compensate"
  handler       = "index.handler"
  runtime       = "nodejs20.x"

  create_package         = false
  local_existing_package = "${path.root}/../../dist/compensate.zip"

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
        Resource = module.lambda_invoke.lambda_function_arn
        Catch = [{
          ErrorEquals = ["States.ALL"]
          ResultPath  = "$.error"
          Next        = "Compensate"
        }]
        Next = "Success"
      }
      Compensate = {
        Type     = "Task"
        Resource = module.lambda_compensate.lambda_function_arn
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
        module.lambda_invoke.lambda_function_arn,
        module.lambda_compensate.lambda_function_arn,
      ]
    }
  }
}

output "state_machine_arn" {
  value = module.step_functions.state_machine_arn
}
