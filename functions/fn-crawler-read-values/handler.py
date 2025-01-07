import subprocess
import sys
import os

# Diretório de instalação (alterar conforme necessário)
install_dir = "/tmp/python"

# Pacotes a serem instalados
packages = [
    "boto3==1.35.92",
    "pandas==2.2.3",
    "requests==2.32.3",
    "pyarrow",
    "s3fs"
]

# Instala os pacotes no diretório especificado.
if not os.path.exists(install_dir):
    os.makedirs(install_dir)

# Adicione o diretório ao sys.path
sys.path.append(install_dir)

try:
    # Instale cada pacote usando subprocess
    for package in packages:
        subprocess.check_call([
            sys.executable,
            "-m",
            "pip",
            "install",
            package,
            "--target",
            install_dir
        ])
    print("Pacotes instalados com sucesso.")
except subprocess.CalledProcessError as e:
    print(f"Erro ao instalar os pacotes: {e}")
    raise


import json
import base64
import boto3
import requests
import logging
import pandas as pd
import datetime
import time

# Configura o logger para o Lambda e CloudWatch
logger = logging.getLogger()
logger.setLevel(logging.INFO)

s3 = boto3.client("s3")
bucket_name = "s3://tech-challanger-2-prd-raw-zone-593793061865"
s3_path = f"pregao-ibov/"


def lambda_handler(event, context):
    def generate_encoded_param(page_number):
        """Gera o parâmetro base64 para a URL."""
        try:
            data = {
                "language": "pt-br",
                "pageNumber": page_number,
                "pageSize": 20,
                "index": "IBOV",
            }
            json_data = json.dumps(data)
            encoded_data = base64.b64encode(json_data.encode()).decode("utf-8")
            logger.info(
                f"Parâmetro gerado para a página {page_number}: {encoded_data[:50]}..."
            )
            return encoded_data
        except Exception as e:
            logger.error(
                f"Erro ao gerar o parâmetro base64 para a página {page_number}: {e}"
            )
            raise

    def fetch_data():
        """Busca os dados paginados da API."""
        all_data = []

        headers = {
            "accept": "application/json, text/plain, */*",
            "accept-encoding": "gzip, deflate, br",
            "accept-language": "pt-BR,pt;q=0.9,en-US;q=0.8,en;q=0.7",
            "user-agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36",
            "referer": "https://sistemaswebb3-listados.b3.com.br/",
        }

        try:
            encoded_param = generate_encoded_param(1)
            url = f"https://sistemaswebb3-listados.b3.com.br/indexProxy/indexCall/GetPortfolioDay/{encoded_param}"
            response = requests.get(url, headers=headers)

            if response.status_code != 200:
                logger.error(f"Erro ao buscar dados iniciais: {response.status_code}")
                return None

            json_response = response.json()
            total_pages = json_response.get("page", {}).get("totalPages", 0)

            if total_pages == 0:
                logger.warning("Nenhuma página disponível na resposta.")
                return None

            logger.info(f"Total de páginas: {total_pages}")

            for page_number in range(1, total_pages + 1):
                logger.info(f"Buscando a página {page_number} de {total_pages}...")
                encoded_param = generate_encoded_param(page_number)
                url = f"https://sistemaswebb3-listados.b3.com.br/indexProxy/indexCall/GetPortfolioDay/{encoded_param}"

                try:
                    response = requests.get(url, headers=headers)
                    if response.status_code == 200:
                        json_response = response.json()
                        page_data = json_response.get("results", [])
                        if page_data:
                            all_data.extend(page_data)
                            logger.info(
                                f"Página {page_number}: {len(page_data)} registros encontrados."
                            )
                        else:
                            logger.warning(f"Página {page_number} está vazia.")
                    else:
                        logger.error(
                            f"Falha ao buscar a página {page_number}: {response.status_code}"
                        )
                except Exception as e:
                    logger.error(f"Erro ao buscar dados da página {page_number}: {e}")

                time.sleep(1)  # Evitar sobrecarregar a API

            return all_data

        except Exception as e:
            logger.error(f"Erro na busca de dados: {e}")
            return None

    def save_to_s3(data):
        """Salva os dados no S3 em formato Parquet."""
        try:
            df = pd.DataFrame(data)
            if df.empty:
                logger.warning("Nenhum dado para salvar no S3.")
                return

            file_name = f"dados_ibov_{datetime.date.today()}.parquet"
            local_path = f"{bucket_name}/{s3_path}{file_name}"

            df.to_parquet(f"{local_path}", index=False)
            #s3.upload_file(f"{local_path}", bucket_name, f"{s3_path}{file_name}")
            logger.info(f"Dados salvos no S3: {file_name}")
        except Exception as e:
            logger.error(f"Erro ao salvar os dados no S3: {e}")

    # Fluxo principal
    try:
        data = fetch_data()
        if data:
            save_to_s3(data)
        else:
            logger.error("Nenhum dado foi retornado da API.")
    except Exception as e:
        logger.error(f"Erro na execução do Lambda: {e}")


lambda_handler(True, True)
