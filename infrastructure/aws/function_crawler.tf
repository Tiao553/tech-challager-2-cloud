# Criar Lambda Function
resource "aws_lambda_function" "crawler_lambda" {
  function_name = "${local.prefix}-crawler_pregao"
  role          = aws_iam_role.lambda_decompress.arn
  package_type  = "Image"
  image_uri = "593793061865.dkr.ecr.us-east-1.amazonaws.com/tech-challanger-2-prd-lambda-repo@sha256:4ced531e057d3b6229f8017141d51b1d8208ef53965e77102218180e51b9e088"
  timeout       = 900
  memory_size   = 1024
  architectures = ["x86_64"]

  tags = merge(
    local.common_tags,
  )

  depends_on = [aws_ecr_repository.lambda_repo]
}



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
