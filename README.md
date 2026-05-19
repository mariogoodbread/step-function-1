# step-functions1

Workflow AWS Step Functions con compensazione applicativa.

## Flusso

```
InvokeRestService --> Success
       |
    (errore)
       |
   Compensate --> Failure
```

## Setup

```bash
npm install
npm run build
```

## Deploy

```bash
cd terraform
terraform init

$env:AWS_PROFILE="xxx"

terraform plan -out=tfplan

terraform apply tfplan
```

## Test

Avvia l'esecuzione dalla console AWS o con CLI:

```bash
aws stepfunctions start-execution \
  --state-machine-arn <ARN> \
  --input '{"orderId": "123"}'
```
