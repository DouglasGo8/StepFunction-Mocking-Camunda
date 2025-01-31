{
  "Comment": "Step Function to call EKS microservice",
  "StartAt": "Processamento Operacao Murex",
  "States": {
    "Processamento Operacao Murex": {
      "Type": "Task",
      "Resource": "arn:aws:states:::apigateway:invoke",
      "Parameters": {
        "ApiEndpoint": "MyApiId.execute-api.us-east-1.amazonaws.com",
        "Method": "POST",
        "Path": "/api/process",
        "Headers": {
          "Content-Type": "application/json"
        },
        "Body": {
          "message": "Trigger from Step Function"
        }
      },
      "Next": "ReceiveMessage"
    },
    "ReceiveMessage": {
      "Type": "Task",
      "Parameters": {
        "QueueUrl": "MyData"
      },
      "Resource": "arn:aws:states:::aws-sdk:sqs:receiveMessage.waitForTaskToken",
      "TimeoutSeconds": 3600,
      "Catch": [
        {
          "ErrorEquals": [
            "States.Timeout",
            "Callback Receive Task Error"
          ],
          "Next": "Registrar Incidente"
        }
      ],
      "Next": "Avaliar Mensagem Retorno Murex"
    },
    "Registrar Incidente": {
      "Type": "Task",
      "Resource": "arn:aws:states:::apigateway:invoke",
      "Parameters": {
        "ApiEndpoint": "MyApiId.execute-api.us-east-1.amazonaws.com",
        "Method": "POST",
        "AllowNullValue": true,
        "Headers": {
          "Header1": [
            "HeaderValue1"
          ],
          "Header2": [
            "HeaderValue2",
            "HeaderValue3"
          ]
        },
        "Stage": "MyStage",
        "Path": "/pets/dog/1",
        "QueryParameters": {
          "QueryParameter1": [
            "QueryParameterValue1"
          ],
          "QueryParameter2": [
            "QueryParameterValue2",
            "QueryParameterValue3"
          ]
        },
        "RequestBody": {
          "Payload": "Hello from Step Functions!"
        },
        "AuthType": "IAM_ROLE"
      },
      "End": true
    },
    "Avaliar Mensagem Retorno Murex": {
      "Type": "Task",
      "Resource": "arn:aws:states:::lambda:invoke",
      "OutputPath": "$.Payload",
      "Parameters": {
        "Payload.$": "$"
      },
      "Retry": [
        {
          "ErrorEquals": [
            "Lambda.ServiceException",
            "Lambda.AWSLambdaException",
            "Lambda.SdkClientException",
            "Lambda.TooManyRequestsException"
          ],
          "IntervalSeconds": 1,
          "MaxAttempts": 3,
          "BackoffRate": 2,
          "JitterStrategy": "FULL"
        }
      ],
      "Next": "Registro Murex Efetivado Com Sucesso"
    },
    "Registro Murex Efetivado Com Sucesso": {
      "Type": "Choice",
      "Choices": [
        {
          "End": true
        }
      ],
      "Default": "Atualizar Status de Erro no Registo"
    },
    "Atualizar Status de Erro no Registo": {
      "Type": "Task",
      "Resource": "arn:aws:states:::dynamodb:updateItem",
      "Parameters": {
        "TableName": "MyDynamoDBTable",
        "Key": {
          "Column": {
            "S": "MyEntry"
          }
        },
        "UpdateExpression": "SET MyKey = :myValueRef",
        "ExpressionAttributeValues": {
          ":myValueRef": {
            "S": "MyValue"
          }
        }
      },
      "Next": "Criar Solicitacao Registro Incidente"
    },
    "Criar Solicitacao Registro Incidente": {
      "Type": "Task",
      "Resource": "arn:aws:states:::sqs:sendMessage",
      "Parameters": {
        "MessageBody.$": "$"
      },
      "Next": "Envio SNS Link Formulario Aprovacao"
    },
    "Envio SNS Link Formulario Aprovacao": {
      "Type": "Task",
      "Resource": "arn:aws:states:::lambda:invoke.waitForTaskToken",
      "OutputPath": "$.Payload",
      "Parameters": {
        "Payload.$": "$"
      },
      "Retry": [
        {
          "ErrorEquals": [
            "Lambda.ServiceException",
            "Lambda.AWSLambdaException",
            "Lambda.SdkClientException",
            "Lambda.TooManyRequestsException"
          ],
          "IntervalSeconds": 1,
          "MaxAttempts": 3,
          "BackoffRate": 2,
          "JitterStrategy": "FULL"
        }
      ],
      "Next": "Wait for HT Approval"
    },
    "Wait for HT Approval": {
      "Type": "Choice",
      "Choices": [
        {
          "Next": "Approved HT"
        }
      ],
      "Default": "Not Approved HT"
    },
    "Approved HT": {
      "Type": "Succeed"
    },
    "Not Approved HT": {
      "Type": "Fail"
    }
  }
}