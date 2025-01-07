# Tech challenge 2 - Arquitetura cloud
---



Para construção da arquitetura base vamos utilizar o terraform e o framework blueprint da empresa do Sebastião o Rony que cria um setup aws base para nossa aplicação e vamos incrementando com base a nessecidade do projeto.

primeiramente vamos configurar o aws cli para acesso externo à aws.

---

# Instalação do AWS CLI no Linux

Este guia descreve o processo de instalação do AWS Command Line Interface (CLI) em sistemas Linux.

## Requisitos

- Um sistema Linux com acesso à internet.
- Permissões de administrador para instalar pacotes.

## Passos de Instalação

1. **Atualizar os pacotes do sistema**

   Antes de começar, certifique-se de que seu sistema está atualizado:
   ```bash
   sudo apt update && sudo apt upgrade -y
   ```
   *(Substitua `apt` por `yum`, `dnf` ou o gerenciador de pacotes da sua distribuição, se aplicável.)*

2. **Baixar o binário do AWS CLI**

   Use o comando `curl` para baixar a versão mais recente do AWS CLI:
   ```bash
   curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
   ```

3. **Extrair o arquivo compactado**

   Extraia o conteúdo do arquivo ZIP:
   ```bash
   unzip awscliv2.zip
   ```

   Caso o comando `unzip` não esteja instalado, instale-o usando:
   ```bash
   sudo apt install unzip -y
   ```

4. **Instalar o AWS CLI**

   Execute o script de instalação:
   ```bash
   sudo ./aws/install
   ```

5. **Verificar a Instalação**

   Confirme que a instalação foi bem-sucedida verificando a versão instalada:
   ```bash
   aws --version
   ```
   O resultado esperado deve ser semelhante a:
   ```
   aws-cli/2.x.x Python/3.x.x Linux/x86_64
   ```

## Opções de Configuração (Opcional)

Depois de instalar, configure o AWS CLI com suas credenciais:
```bash
aws configure
```
Você precisará fornecer:
- Access Key ID
- Secret Access Key
- Região padrão (ex.: `us-east-1`)
- Formato de saída (opcional, ex.: `json`)

## Limpeza

Após a instalação, você pode remover os arquivos de instalação para liberar espaço:
```bash
rm -rf awscliv2.zip aws
```

## Problemas Comuns

1. **Permissão negada**: Se encontrar erros relacionados a permissão, use `sudo` para os comandos.
2. **AWS CLI não encontrado**: Certifique-se de que o diretório de instalação está incluído no PATH:
   ```bash
   export PATH=/usr/local/bin:$PATH
   ```

Agora você está pronto para usar o AWS CLI em seu sistema Linux e o proximo passo é configurar o terraform.

---

# Instalação do Terraform no Linux

Este guia descreve o processo de instalação do Terraform em sistemas Linux.

## Requisitos

- Um sistema Linux com acesso à internet.
- Permissões de administrador para instalar pacotes.

## Passos de Instalação

1. **Atualizar os pacotes do sistema**

   Antes de começar, certifique-se de que seu sistema está atualizado:
   ```bash
   sudo apt update && sudo apt upgrade -y
   ```
   *(Substitua `apt` por `yum`, `dnf` ou o gerenciador de pacotes da sua distribuição, se aplicável.)*

2. **Baixar o binário do Terraform**

   Baixe a versão mais recente do Terraform diretamente do site oficial da HashiCorp:
   ```bash
   curl -fsSL "https://releases.hashicorp.com/terraform/$(curl -s https://releases.hashicorp.com/terraform/ | grep -oP 'terraform/[0-9]+\.[0-9]+\.[0-9]+' | head -n 1 | cut -d '/' -f 2)/terraform_$(curl -s https://releases.hashicorp.com/terraform/ | grep -oP 'terraform/[0-9]+\.[0-9]+\.[0-9]+' | head -n 1 | cut -d '/' -f 2)_linux_amd64.zip" -o terraform.zip
   ```

3. **Extrair o arquivo compactado**

   Extraia o conteúdo do arquivo ZIP:
   ```bash
   unzip terraform.zip
   ```

   Caso o comando `unzip` não esteja instalado, instale-o usando:
   ```bash
   sudo apt install unzip -y
   ```

4. **Mover o binário para um diretório no PATH**

   Mova o binário do Terraform para um diretório que esteja no PATH do sistema:
   ```bash
   sudo mv terraform /usr/local/bin/
   ```

5. **Verificar a Instalação**

   Confirme que a instalação foi bem-sucedida verificando a versão instalada:
   ```bash
   terraform --version
   ```
   O resultado esperado deve ser semelhante a:
   ```
   Terraform vX.Y.Z
   ```

## Limpeza

Após a instalação, você pode remover os arquivos temporários:
```bash
rm -rf terraform.zip
```

## Problemas Comuns

1. **Terraform não encontrado**: Certifique-se de que o binário foi movido para um diretório no PATH. Reinicie o terminal se necessário.
2. **Versão incorreta**: Certifique-se de que baixou a versão correta do Terraform para o seu sistema operacional e arquitetura.

Agora você está pronto para usar o Terraform em seu sistema Linux para gerenciar infraestrutura como código!
