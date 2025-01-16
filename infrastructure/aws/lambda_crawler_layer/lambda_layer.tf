resource "null_resource" "download_and_process" {
  provisioner "local-exec" {
    command = <<EOT
      # Baixa o arquivo ZIP do S3
      aws s3 cp s3://tech-challanger-2-prd-temp-functions-593793061865/fn-crawler-read-values/fn-crawler-read-values.zip ./fn-crawler-read-values.zip

      # Cria o diretório para descompactar e processar os arquivos
      mkdir -p ./lambda_layer

      # Extrai o conteúdo do ZIP
      unzip -o ./fn-crawler-read-values.zip -d ./lambda_layer

      # Instala os pacotes do requirements otimizado
      pip install -r ./lambda_layer/fn-crawler-read-values/requirements.txt -t ./lambda_layer/fn-crawler-read-values/python/ 

      # Remove arquivos desnecessários
      find ./lambda_layer/fn-crawler-read-values//python -type d -name "tests" -exec rm -rf {} +
      find ./lambda_layer/fn-crawler-read-values//python -type d -name "docs" -exec rm -rf {} +
      find ./lambda_layer/fn-crawler-read-values//python -name "*.pyc" -delete
      find ./lambda_layer/fn-crawler-read-values//python -name "*.pyo" -delete
      find ./lambda_layer/fn-crawler-read-values//python -name "*.dist-info" -exec rm -rf {} +

      # Verifica o tamanho
      total_size=$(du -sm ./lambda_layer | cut -f1)
      if [ $total_size -gt 250 ]; then
        echo "Tamanho excede 250MB. Otimização adicional necessária."
        exit 1
      fi

      # Compacta tudo em um novo ZIP para a Layer
      cd ./lambda_layer/fn-crawler-read-values && zip -r ./lambda_layer_processed.zip ./*

      # Upload do arquivo para o S3
      aws s3 cp ./lambda_layer_processed.zip s3://tech-challanger-2-prd-temp-functions-593793061865/fn-layers/layer_processed.zip
    EOT
  }
  triggers = {
    always_run = "${timestamp()}"
  }
}

# Criar Lambda Layer
resource "aws_lambda_layer_version" "lambda_layer" {
  layer_name          = "crawler_layer_dependencies"
  s3_bucket           = "tech-challanger-2-prd-temp-functions-593793061865"
  s3_key              = "fn-layers/layer_processed.zip"
  compatible_runtimes = ["python3.9"]
  depends_on = [null_resource.download_and_process]
}