# Criar Lambda Function
resource "aws_lambda_function" "crawler_lambda" {
  function_name = "${local.prefix}-crawler_pregao"
  s3_bucket     = "tech-challanger-2-prd-temp-functions-593793061865"
  s3_key        = "fn-crawler-read-values/fn-crawler-read-values.zip" 
  role          = aws_iam_role.lambda_decompress.arn
  handler       = "fn-crawler-read-values.handler.lambda_handler"
  runtime       = "python3.10"
  timeout       = 900
  memory_size   = 1024
}

# Lambda Function
# resource "aws_lambda_function" "crawler_lambda" {
#   function_name = "${local.prefix}-crawler_pregao"
#   role          = aws_iam_role.lambda_role.arn
#   package_type  = "${local.prefix}-lambda-crawler-repo"
#   image_uri     = "${aws_ecr_repository.lambda_repo.repository_url}:latest"
#   timeout       = 900
#   memory_size   = 1024
#   environment {
#     variables = {
#       LAMBDA_TASK_ROOT = "/app/"
#     }
#   }
# }



# Agendamento no CloudWatch (EventBridge)
resource "aws_cloudwatch_event_rule" "daily_trigger" {
  name                = "${local.prefix}-DailyTrigger"
  description         = "Dispara a função Lambda diariamente às 20h"
  schedule_expression = "cron(0 20 * * ? *)" #alteração pra teste
}

# Permissão para EventBridge chamar a Lambda
resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.crawler_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.daily_trigger.arn
}

# Vincula o Rule à Lambda
resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.daily_trigger.name
  target_id = "${local.prefix}_crawler_pregao"
  arn       = aws_lambda_function.crawler_lambda.arn
}
