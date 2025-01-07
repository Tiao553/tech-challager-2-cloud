# resource "aws_lambda_function" "decompresss3" {
#   filename      = "../../functions/fn_example_script.zip"
#   function_name = "${local.prefix}_decompressS3"
#   role          = aws_iam_role.lambda_decompress.arn
#   handler       = "handler.handler"
#   runtime     = "python3.8"
#   timeout     = 900
#   memory_size = 1000
#   tags = local.common_tags
# }

resource "null_resource" "install_dependencies" {
  triggers = {
    s3_bucket     = "tech-challanger-2-prd-temp-functions-593793061865"
    s3_key        = "fn-crawler-read-values/fn-crawler-read-values.zip"
  }

  provisioner "local-exec" {
    command = <<EOF
      mkdir -p lambda_layer/python
      unzip -p s3://${aws_s3_bucket.lambda_bucket.id}/${aws_s3_object.lambda_package.key} requirements.txt > lambda_layer/requirements.txt
      pip install -r lambda_layer/requirements.txt -t lambda_layer/python
      cd lambda_layer && zip -r ../lambda_layer.zip .
    EOF
  }
}


resource "aws_lambda_layer_version" "dependencies_layer" {
  filename            = "lambda_layer.zip"
  layer_name          = "my_dependencies_layer"
  compatible_runtimes = ["python3.9"]

  depends_on = [null_resource.install_dependencies]
}

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

  layers = [aws_lambda_layer_version.dependencies_layer.arn]
}



# # Agendamento no CloudWatch (EventBridge)
# resource "aws_cloudwatch_event_rule" "daily_trigger" {
#   name        = "${local.prefix}_DailyTrigger"
#   description = "Dispara a função Lambda diariamente às 20h"
#   schedule_expression = "cron(0 20 * * ? *)" # CRON para 20h (UTC)
# }

# # Permissão para EventBridge chamar a Lambda
# resource "aws_lambda_permission" "allow_eventbridge" {
#   statement_id  = "AllowExecutionFromEventBridge"
#   action        = "lambda:InvokeFunction"
#   function_name = aws_lambda_function.example_s3_lambda.function_name
#   principal     = "events.amazonaws.com"
#   source_arn    = aws_cloudwatch_event_rule.daily_trigger.arn
# }

# # Vincula o Rule à Lambda
# resource "aws_cloudwatch_event_target" "lambda_target" {
#   rule      = aws_cloudwatch_event_rule.daily_trigger.name
#   target_id = "LambdaFunction"
#   arn       = aws_lambda_function.example_s3_lambda.arn
# }