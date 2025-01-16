# Libs for generaal porpuse
import logging
import os
import boto3
import time

# Libs for crawler
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from webdriver_manager.chrome import ChromeDriverManager

# Libs for data processing
import pandas as pd
import datetime
from pydantic import BaseModel, Field, ValidationError
from typing import List
from io import StringIO


# Configura o logger para o Lambda e CloudWatch
logger = logging.getLogger()
logger.setLevel(logging.INFO)

s3 = boto3.client("s3")
bucket_name = "s3://tech-challanger-2-prd-raw-zone-593793061865"
s3_path = f"pregao-ibov/"


def lambda_handler(event, context):
    class StockData(BaseModel):
        Codigo: str
        Acao: str
        Tipo: str
        Qtde_Teorica: int = Field(alias='Qtde. Teorica')
        Part: float = Field(alias='Part.(%)')

    def scrapping() -> str:
        # Configuração do diretório de download
        current_dir = os.getcwd()
        print(f"Current Directory: {current_dir}")

        # Define the new folder name
        folder_name = "downloads"

        # Create the full path for the new folder
        download_dir = os.path.join(current_dir, folder_name)

        # Check if the folder already exists
        if not os.path.exists(download_dir):
            os.makedirs(download_dir)
            print(f"Folder '{folder_name}' created at: {download_dir}")
        else:
            print(f"Folder '{folder_name}' already exists at: {download_dir}")

        # Configuração das opções do Chrome
        chrome_options = Options()
        chrome_options.add_experimental_option("prefs", {
            "download.default_directory": download_dir,  # Define o diretório de download
            "download.prompt_for_download": False,  # Não perguntar onde salvar
            "download.directory_upgrade": True,  # Atualizar o diretório automaticamente
            "safebrowsing.enabled": True,  # Habilitar downloads seguros
        })
        chrome_options.add_argument("--headless")
        chrome_options.add_argument("--disable-gpu")
        chrome_options.add_argument("--no-sandbox")

        # Configuração do driver do Chrome 
        # Inicializa o driver com o ChromeDriver gerenciado automaticamente
        driver = webdriver.Chrome(
            service=Service(
                ChromeDriverManager().install(),
            ), options=chrome_options,
        )

        try:
            # Abre o site
            print("Acessando o site...")
            driver.get("https://sistemaswebb3-listados.b3.com.br/indexPage/day/IBOV?language=pt-br")

            # Aguarda até que o botão de download esteja visível e clicável
            print()
            download_button = WebDriverWait(driver, 60).until(
                EC.element_to_be_clickable((By.LINK_TEXT, "Download"))
            )

            # Simula o clique no botão de download
            download_button.click()

            # Aguarda o download ser concluído (ajuste o tempo conforme necessário)
            print("Baixando o arquivo...")
            time.sleep(5)

            # Verifica se o arquivo foi baixado
            downloaded_files = [f for f in os.listdir(download_dir) if f.endswith(".csv")]
            if downloaded_files:
                print("Download concluído com sucesso!")
            else:
                print("O arquivo não foi baixado.")

        except Exception as e:
            print(f"Erro: {e}")

        finally:
            driver.quit()

        return download_dir

    

    def remove_linhas_mescladas(path_file) -> pd.DataFrame: 
        try:
            with open(f"{path_file}", "r", encoding="iso-8859-1") as file:
                file_content = file.readlines()  # Call the read method correctly
            # Dividir o conteúdo do arquivo em linhas
            lines = file_content
            print(f"Total lines read: {len(lines)}")  # Debugging statement
            
            # Remover a primeira e as duas últimas linhas
            file_content = file_content[1:-2]

            # Reunir as linhas restantes
            cleaned_content = "\n".join(file_content)
            
            # Substituir ',' por '.'
            cleaned_content = cleaned_content.replace(',', '.')

            # Carregar o conteúdo no pandas
            return pd.read_csv(StringIO(cleaned_content), sep=";",index_col=False)
        except Exception as e:
            print(f"Erro ao remover linhas mescladas: {e}")


    def pre_processamento(df: pd.DataFrame) -> pd.DataFrame:
        # Renomeando as colunas
        df.columns = ['Codigo', 'Acao', 'Tipo', 'Qtde. Teorica', 'Part.(%)']
        # Validando e convertendo os dados usando Pydantic
        try:
            df['Qtde. Teorica'] = df['Qtde. Teorica'].str.replace('.', '').astype(int)
            data = df.to_dict(orient='records')
            validated_data = [StockData(**item).dict() for item in data]
            return pd.DataFrame(validated_data)
        except ValidationError as e:
            print(e.json())
            return pd.DataFrame()

    def save_to_s3(df, file_name):
        """Salva os dados no S3 em formato Parquet."""
        try:
            if df.empty:
                logger.warning("Nenhum dado para salvar no S3.")
                return

            local_path = f"{bucket_name}/{s3_path}{file_name}"

            df.to_parquet(f"{local_path}", index=False)
            # s3.upload_file(f"{local_path}", bucket_name, f"{s3_path}{file_name}")
            logger.info(f"Dados salvos no S3: {file_name}")
        except Exception as e:
            logger.error(f"Erro ao salvar os dados no S3: {e}")

    # Fluxo principal
    try:
        data = scrapping()
        # Obter a data atual
        today = datetime.date.today()
        # Formatar a data no formato desejado
        formatted_date = today.strftime("%d-%m-%y")
        path_download = f"/home/tiao/tech-challager-2-cloud/downloads/IBOVDia_{formatted_date}.csv"
        if data:
            file_name = f"dados_ibov_{datetime.date.today()}.parquet"
            df = remove_linhas_mescladas(path_download)
            data_processed = pre_processamento(df)
            save_to_s3(data_processed, file_name)
        else:
            logger.error("Nenhum dado foi retornado da API.")
    except Exception as e:
        logger.error(f"Erro na execução do Lambda: {e}")


lambda_handler(True, True)