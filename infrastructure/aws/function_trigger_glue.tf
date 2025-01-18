# Criar Lambda Function
resource "aws_lambda_function" "glue_lambda" {
  function_name = "${local.prefix}-trigger-glue-agregate"
  s3_bucket     = "tech-challanger-2-prd-temp-functions-593793061865"
  s3_key        = "fn-trigger-glue-job/fn-trigger-glue-job.zip"
  role          = aws_iam_role.lambda_decompress.arn
  handler       = "fn-trigger-glue-job.handler.lambda_handler"
  runtime       = "python3.10"
  timeout       = 900
  memory_size   = 128
}

# Permissão para que o S3 invoque a Lambda
resource "aws_lambda_permission" "allow_s3_invocation" {
  statement_id  = "AllowExecutionFromS3"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.glue_lambda.function_name
  principal     = "s3.amazonaws.com"

  # ARN do bucket que irá acionar a Lambda
  source_arn = "arn:aws:s3:::tech-challanger-2-prd-raw-zone-593793061865"
}

# Configuração da notificação do bucket S3
resource "aws_s3_bucket_notification" "lambda_trigger" {
  bucket = "tech-challanger-2-prd-raw-zone-593793061865"

  lambda_function {
    lambda_function_arn = aws_lambda_function.glue_lambda.arn
    events              = ["s3:ObjectCreated:*"] # Aciona quando um novo arquivo é criado
    filter_prefix       = "pregao-ibov/*"         # Prefixo da chave (pasta específica)
    filter_suffix       = ".parquet"             # Sufixo do arquivo (extensão específica)
  }

  # Garante que a permissão seja criada antes de configurar a notificação
  depends_on = [aws_lambda_permission.allow_s3_invocation]
}
