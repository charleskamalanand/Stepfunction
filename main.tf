# Configure the AWS Provider
provider "aws" {
  region = "us-east-2"
}


variable "All_Variables" {
  type    = list(string)
  default = ["us-east-2", "9xxxxxxxxxx4", "Dev", "Deployed from terraform"]
}

data "archive_file" "lambda1-zip" {
  type        = "zip"
  source_dir  = "lambda"
  output_path = "lambda.zip"
}

resource "aws_iam_role" "StepFunctionToOtherResources" {
  name = "StepFunctionToOtherResources_Terraform"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "states.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    Name = var.All_Variables[3]
  }
}
resource "aws_iam_role_policy_attachment" "StepFunction_Policy_Attachment" {
  role       = aws_iam_role.StepFunctionToOtherResources.name
  policy_arn = aws_iam_policy.StepFunctionToOtherResourcesPolicy.arn
}

resource "aws_iam_policy" "StepFunctionToOtherResourcesPolicy" {
  name        = "StepFunctionToOtherResourcesPolicy_Terraform"
  path        = "/"
  description = "IAM policy for logging from a lambda and for send message to SQS"

  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Action" : [
            "dynamodb:GetItem",
            "dynamodb:PutItem",
            "dynamodb:UpdateItem",
            "dynamodb:DeleteItem"
          ],
          #"Resource": "arn:aws:dynamodb:us-east-2:9**********4:table/StepFunctionDemo"
          "Resource" : join(":table/", [join(":", [join("", ["arn:aws:dynamodb:", var.All_Variables[0]]), var.All_Variables[1]]), aws_dynamodb_table.StepFunctionDemo.name])
          "Effect" : "Allow"
        },
        {
          "Action" : [
            "lambda:InvokeFunction"
          ],
          #"Resource": "arn:aws:lambda:us-east-2:9**********4:function:StepFunctionDemo"
          "Resource" : [
                      join(":function:", [join(":", [join("", ["arn:aws:lambda:", var.All_Variables[0]]), var.All_Variables[1]]), aws_lambda_function.StepFunctionDemo_lambda.function_name]),
                      join("",[join(":function:", [join(":", [join("", ["arn:aws:lambda:", var.All_Variables[0]]), var.All_Variables[1]]), aws_lambda_function.StepFunctionDemo_lambda.function_name]),":*"])
                      ]
          "Effect" : "Allow"
        }
      ]
  })
  tags = {
    Name = var.All_Variables[3]
  }
}
 
resource "aws_dynamodb_table" "StepFunctionDemo" {
  name             = "StepFunctionDemo"
  hash_key         = "customerId"
  billing_mode     = "PAY_PER_REQUEST"
  range_key = "orderId"


  attribute {
    name = "customerId"
    type = "S"
  }
    attribute {
    name = "orderId"
    type = "S"
  }
  tags = {
    Name = var.All_Variables[3]
  }
}

resource "aws_lambda_function" "Invoke_StepFunctionDemo" {
  filename      = "lambda.zip"
  function_name = "InvokeStepFunctions"
  role          = aws_iam_role.InvokeStepFunctionDemo.arn
  handler       = "InvokeStepFunctions.lambda_handler"
  runtime       = "python3.9"
  tags = {
    Name = var.All_Variables[3]
  }
}


resource "aws_iam_role" "InvokeStepFunctionDemo" {
  name = "InvokeStepFunctionLambdaRole_Terraform"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    Name = var.All_Variables[3]
  }
}
resource "aws_iam_role_policy_attachment" "InvokeStepFunctionDemo_Policy_Attachment" {
  role       = aws_iam_role.InvokeStepFunctionDemo.name
  policy_arn = aws_iam_policy.InvokeStepFunctionLambdaPolicy.arn
}

resource "aws_iam_policy" "InvokeStepFunctionLambdaPolicy" {
  name        = "InvokeStepFunctionLambdaPolicy_Terraform"
  path        = "/"
  description = "IAM policy for logging"

  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Action" : [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ],
          #"Resource": "arn:aws:logs:us-east-2:9**********4:*"
          "Resource" : join(":*", [join(":", [join("", ["arn:aws:logs:", var.All_Variables[0]]), var.All_Variables[1]]), ""]),
          "Effect" : "Allow"
        },
        {
          "Action" : [
            "states:StartExecution"            
          ],
          #arn:aws:states:us-east-2:951560400874:stateMachine:step_function_demo
          #arn:aws:dynamodb:us-east-2:9**********4:table/ProductVisits/stream/*"
          "Resource" : join(":stateMachine:", [join(":", [join("", ["arn:aws:states:", var.All_Variables[0]]), var.All_Variables[1]]), aws_sfn_state_machine.sfn_state_machine.name])
          "Effect" : "Allow"
        }
      ]
  })
  tags = {
    Name = var.All_Variables[3]
  }
}

resource "aws_lambda_function" "StepFunctionDemo_lambda" {
  filename      = "lambda.zip"
  function_name = "StepFunctionDemo"
  role          = aws_iam_role.lambdaRoleForStepFunctionDemo.arn
  handler       = "StepFunctionDemo.lambda_handler"
  runtime       = "python3.9"
  tags = {
    Name = var.All_Variables[3]
  }
}

resource "aws_iam_role" "lambdaRoleForStepFunctionDemo" {
  name = "StepFunctionDemoLambdaRole_Terraform"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    Name = var.All_Variables[3]
  }
}
resource "aws_iam_role_policy_attachment" "StepFunctionDemo_Policy_Attachment" {
  role       = aws_iam_role.lambdaRoleForStepFunctionDemo.name
  policy_arn = aws_iam_policy.StepFunctionDemoLambdaPolicy.arn
}

resource "aws_iam_policy" "StepFunctionDemoLambdaPolicy" {
  name        = "StepFunctionDemoLambdaPolicy"
  path        = "/"
  description = "IAM policy for logging"

  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Action" : [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ],
          #"Resource": "arn:aws:logs:us-east-2:9**********4:*"
          "Resource" : join(":*", [join(":", [join("", ["arn:aws:logs:", var.All_Variables[0]]), var.All_Variables[1]]), ""]),
          "Effect" : "Allow"
        }
      ]
  })
  tags = {
    Name = var.All_Variables[3]
  }
}

resource "aws_apigatewayv2_api" "StepFunctionDemo" {
  name          = "StepFunctionDemo"
  protocol_type = "HTTP"
  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["*"]
    allow_headers = ["*"]
  }
  tags = {
    Name = var.All_Variables[3]
  }
}


resource "aws_apigatewayv2_integration" "API_Integration_StepFunctionDemo" {
  api_id               = aws_apigatewayv2_api.StepFunctionDemo.id
  integration_type     = "AWS_PROXY"
  connection_type      = "INTERNET"
  description          = "Lambda example"
  integration_method   = "POST"
  integration_uri      = aws_lambda_function.Invoke_StepFunctionDemo.invoke_arn
  passthrough_behavior = "WHEN_NO_MATCH"
}

resource "aws_apigatewayv2_route" "API_Route_productVisit" {
  api_id    = aws_apigatewayv2_api.StepFunctionDemo.id
  route_key = "POST /sendOrder"
  target    = "integrations/${aws_apigatewayv2_integration.API_Integration_StepFunctionDemo.id}"
}

resource "aws_apigatewayv2_stage" "API_Stage_productVisit" {
  api_id      = aws_apigatewayv2_api.StepFunctionDemo.id
  name        = var.All_Variables[2]
  auto_deploy = true
}

resource "aws_lambda_permission" "Lambda_Permission_StepFunctionDemo" {
  statement_id  = "AllowMyDemoAPIInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.Invoke_StepFunctionDemo.arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.StepFunctionDemo.execution_arn}/*/*/sendOrder"
}

output "API_URL" {
  description = "Paste this in the Static S3 html"
  value = "${aws_apigatewayv2_api.StepFunctionDemo.api_endpoint}/${var.All_Variables[2]}/sendOrder"
}

resource "aws_sfn_state_machine" "sfn_state_machine" {
  name     = "step_function_demo"
  role_arn = aws_iam_role.StepFunctionToOtherResources.arn

  definition = <<EOF
{
  "Comment": "A description of my state machine",
  "StartAt": "Add info in DB",
  "States": {
    "Add info in DB": {
      "Type": "Task",
      "Resource": "arn:aws:states:::dynamodb:putItem",
      "Parameters": {
        "TableName": "${aws_dynamodb_table.StepFunctionDemo.name}",
        "Item": {
          "customerId": {
            "S.$": "$.customerId"
          },
          "orderId": {
            "S.$": "$.orderId"
          }
        }
      },
      "Next": "Successful?",
      "ResultSelector": {
        "statuscode.$": "$.SdkHttpMetadata.HttpStatusCode"
      },
      "ResultPath": "$.result"
    },
    "Successful?": {
      "Type": "Choice",
      "Choices": [
        {
          "Variable": "$.result.statuscode",
          "NumericEquals": 200,
          "Next": "Process in Lambda"
        }
      ],
      "Default": "Fail"
    },
    "Process in Lambda": {
      "Type": "Task",
      "Resource": "arn:aws:states:::lambda:invoke",
      "Parameters": {
        "Payload.$": "$",
        "FunctionName": "${join("",[aws_lambda_function.StepFunctionDemo_lambda.arn,":$LATEST"])}"
      },
      "Retry": [
        {
          "ErrorEquals": [
            "Lambda.ServiceException",
            "Lambda.AWSLambdaException",
            "Lambda.SdkClientException"
          ],
          "IntervalSeconds": 2,
          "MaxAttempts": 6,
          "BackoffRate": 2
        }
      ],
      "Next": "Success",
      "ResultPath": "$.result",
      "Catch": [
        {
          "ErrorEquals": [
            "States.ALL"
          ],
          "Next": "Wait",
          "ResultPath": "$.result"
        }
      ]
    },
    "Wait": {
      "Type": "Wait",
      "Seconds": 10,
      "Next": "Fall back Delete from DB"
    },
    "Fall back Delete from DB": {
      "Type": "Task",
      "Resource": "arn:aws:states:::dynamodb:deleteItem",
      "Parameters": {
        "TableName": "${aws_dynamodb_table.StepFunctionDemo.name}",
        "Key": {
          "customerId": {
            "S.$": "$.customerId"
          },
          "orderId": {
            "S.$": "$.orderId"
          }
        }
      },
      "Next": "Fail"
    },
    "Success": {
      "Type": "Succeed"
    },
    "Fail": {
      "Type": "Fail"
    }
  }
}
EOF
}

