#!/bin/bash

# Definir o nome do bucket S3
BUCKET_NAME="tech-challanger-2-prd-temp-functions-593793061865"

# Caminho base (pasta atual)
BASE_PATH=$(pwd)

# Função para zipar e fazer upload
zip_and_upload() {
    FOLDER_PATH=$1
    FOLDER_NAME=$(basename "$FOLDER_PATH")

    # Criar o arquivo ZIP
    ZIP_FILE="$FOLDER_NAME.zip"
    echo "Zipping $FOLDER_PATH into $ZIP_FILE..."
    zip -r "$ZIP_FILE" "$FOLDER_PATH" > /dev/null

    # Fazer o upload para o bucket S3
    echo "Uploading $ZIP_FILE to s3://$BUCKET_NAME/$FOLDER_NAME/$ZIP_FILE..."
    aws s3 cp "$ZIP_FILE" "s3://$BUCKET_NAME/$FOLDER_NAME/"

    # Remover o arquivo ZIP local
    rm "$ZIP_FILE"
    echo "Done with $FOLDER_NAME."
}

# Iterar sobre as pastas
for FOLDER in fn-*; do
    if [ -d "$FOLDER" ]; then
        zip_and_upload "$FOLDER"
    fi
done

echo "All done!"
