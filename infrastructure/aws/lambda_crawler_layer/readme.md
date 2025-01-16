# Decisão de Implementação para Função AWS Lambda com Dependências Excedendo 250MB

## Contexto

Ao desenvolver uma solução para executar uma função AWS Lambda, nos deparamos com uma limitação do tamanho das layers. O limite máximo permitido para layers descompactadas é de **250 MB**, e nossas dependências ultrapassaram esse limite.

Diante dessa restrição, analisamos diferentes opções para contornar o problema e garantir que a função pudesse ser executada conforme o esperado. Abaixo estão as opções avaliadas e a decisão final adotada.

---

## Opções Consideradas

### 1. Criar Múltiplas Layers

#### Descrição:
Dividir as dependências em mais de uma layer, mantendo cada layer dentro do limite de 250 MB.

#### Prós:
- Solução suportada nativamente pelo AWS Lambda.
- Reutilização das layers em diferentes funções Lambda.

#### Contras:
- Requer um gerenciamento mais complexo das layers.
- Potencial aumento no tempo de carregamento da função Lambda devido à necessidade de carregar múltiplas layers.

---

### 2. Usar Imagem Docker

#### Descrição:
Criar uma imagem Docker contendo o código e as dependências necessárias. O AWS Lambda suporta imagens de até 10 GB, o que resolveria o problema de limitação de tamanho.

#### Prós:
- Restrição de tamanho significativamente maior (10 GB).
- Ambiente controlado e consistente, com todas as dependências incluídas.
- Flexibilidade para gerenciar o ambiente com maior granularidade.

#### Contras:
- Introduz complexidade adicional ao pipeline de desenvolvimento e implantação.
- Requer manutenção de um repositório de imagens (como o Amazon ECR).

---

### 3. Instalar Dependências Durante a Execução

#### Descrição:
Configurar a função Lambda para instalar as dependências necessárias durante a execução.

#### Prós:
- Implementação simples e direta.
- Nenhum impacto no tamanho da layer ou necessidade de criar uma imagem Docker.

#### Contras:
- Aumenta o tempo de execução da função Lambda, especialmente na primeira chamada (cold start).
- Pode impactar a eficiência geral dependendo do número de chamadas concorrentes.

---

## Decisão Final

Optamos por **instalar as dependências durante a execução da função Lambda** (Opção 3). Embora essa abordagem tenha o contrapeso de um maior tempo de execução inicial, foi considerada a solução mais simples de implementar, dado que o SLA da função é diário e não exige resposta em tempo real.

### Motivação:
1. **Simplicidade**: A solução elimina a necessidade de criar e gerenciar layers ou imagens Docker.
2. **Flexibilidade**: Permite adicionar ou atualizar dependências sem necessidade de alterar layers ou imagens.
3. **Adequado ao SLA**: O impacto no tempo de execução inicial é irrelevante dado que a função é executada apenas uma vez por dia.

---

## Implementação

### Etapas para Instalar Dependências Durante a Execução:

1. Adicionar um script para instalar as dependências no runtime.
2. Configurar a função Lambda para acessar o repositório ou local de instalação (como o PyPI).
3. Verificar o desempenho e ajustar conforme necessário para garantir que o tempo de execução esteja dentro dos limites aceitáveis.

Exemplo de instalação dinâmica em Python:

```python
import subprocess
import sys

def install_packages():
    packages = ["boto3", "pandas"]
    for package in packages:
        subprocess.check_call([sys.executable, "-m", "pip", "install", package, "--target", "/tmp"])

install_packages()
```

---

## Considerações Finais

Essa decisão pode ser revisitada no futuro caso o comportamento esperado mude ou surjam novas restrições. Em cenários onde o tempo de execução se torne um fator crítico, a migração para uma imagem Docker ou a divisão em múltiplas layers pode ser reavaliada.

