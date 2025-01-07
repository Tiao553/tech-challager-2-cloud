# Lambda Function
resource "aws_lambda_function" "crawler_lambda" {
  function_name = "${local.prefix}_crawler_pregao"
  s3_bucket     = "tech-challanger-2-prd-temp-functions-593793061865"
  s3_key        = "fn-crawler-read-values/fn-crawler-read-values.zip"
  role          = aws_iam_role.lambda_decompress.arn
  handler       = "fn-crawler-read-values.handler.lambda_handler" # Nome do arquivo e da função principal
  runtime       = "python3.9"
  timeout       = 900
  memory_size   = 1024

  tags = local.common_tags
}

# Agendamento no CloudWatch (EventBridge)
resource "aws_cloudwatch_event_rule" "daily_trigger" {
  name        = "${local.prefix}_DailyTrigger"
  description = "Dispara a função Lambda diariamente às 20h"
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