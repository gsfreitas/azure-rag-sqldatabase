# 🗄️ Azure SQL Database + Azure OpenAI: Arquitetura RAG 100% Nativa

Este repositório apresenta a implementação prática de uma arquitetura **RAG (Retrieval-Augmented Generation)** executada inteiramente dentro do motor relacional do **Azure SQL Database**, integrando-se nativamente com o **Azure OpenAI**. 

O principal diferencial deste projeto é a aplicação do conceito *"trazer o modelo para onde os dados estão"*. Eliminamos a necessidade de orquestradores externos em Python (como LangChain ou LlamaIndex) ou bancos vetoriais dedicados separados para as tarefas de chunking, embedding e busca semântica.

---

## 🏗️ Fluxo da Arquitetura

O pipeline de dados e inferência é orquestrado de ponta a ponta via Transact-SQL (T-SQL) seguindo quatro etapas principais:

1. **Ingestão e Chunking Nativos:** O texto bruto é inserido e fatiado automaticamente através da função `AI_GENERATE_CHUNKS`.
2. **Vetorização Dinâmica:** Cada fragmento de texto é enviado ao modelo `text-embedding-ada-002` no Azure OpenAI via `AI_GENERATE_EMBEDDINGS`, gerando vetores armazenados no tipo nativo `VECTOR(1536)`.
3. **Recuperação Semântica (Retrieval):** O banco calcula a proximidade geométrica das strings usando similaridade de cosseno com a função `VECTOR_DISTANCE`.
4. **Geração da Resposta (Augmentation & Generation):** O banco consolida os trechos mais relevantes, monta nativamente um payload JSON e invoca o modelo `gpt-4o` usando `sp_invoke_external_rest_endpoint`.

---

## 🛠️ Pré-requisitos e Infraestrutura Azure

Para reproduzir este projeto, a seguinte estrutura foi provisionada no portal da Azure (centralizada no mesmo Resource Group e na região **Brazil South** para conformidade de políticas e baixa latência):

1. **Azure SQL Database**
   * **Camada:** General Purpose (Serverless para otimização de custos).
   * **Configuração de Rede:** *Ponto de extremidade público* ativo.
   * **Regras de Firewall:** 
     * Opção *"Permitir que serviços e recursos do Azure acessem este servidor"* configurada como **Sim** (essencial para o banco alcançar o Azure OpenAI).
     * Endereço IP do cliente atual liberado.

2. **Azure OpenAI (Recurso de Embeddings)**
   * **Região:** Brazil South
   * **Modelo Implantado (Deployment):** `text-embedding-ada-002` (Dimensão: 1536).

3. **Azure OpenAI (Recurso de Chat/LLM)**
   * **Região:** East US 2 (ou região com disponibilidade do modelo de chat).
   * **Modelo Implantado (Deployment):** `gpt-4o` (Versão da API recomendada: `2024-12-01-preview`).

---

## 📂 Estrutura de Arquivos Sugerida

Para manter o repositório organizado e facilitar a execução, os scripts SQL foram divididos em 3 arquivos sequenciais:

*   **`01_setup_infra.sql`**: Habilitação de endpoints, criação da Master Key de criptografia e configuração das credenciais escopo-banco (API Keys).
*   **`02_schema_ingestao.sql`**: Criação das tabelas relacionais/vetoriais e execução da esteira automatizada de fatiamento e embedding inline.
*   **`03_orquestracao_rag.sql`**: Consultas de busca semântica pura e o script completo de integração final com o modelo GPT-4o.

---

## 🚀 Como Executar

### Passo 1: Configuração das Credenciais
Abra o arquivo `01_setup_infra.sql`. Substitua os placeholders pelas chaves secretas (`api-key`) coletadas no seu portal do Azure OpenAI e execute o script para liberar o acesso REST externo do banco.

### Passo 2: Criar Tabelas e Ingerir Dados
Execute o script `02_schema_ingestao.sql`. Ele criará as tabelas `documentos` e `documentos_embeddings`. Ao inserir os dados textuais, o banco usará o `CROSS APPLY` para multiplicar as linhas em múltiplos registros fatiados de 100 caracteres na tabela de vetores.

### Passo 3: Executar a Query de RAG
Abra o script `03_orquestracao_rag.sql`, altere a variável `@pergunta` para o cenário que deseja testar e execute. O retorno exibirá o contexto consolidado pelo banco e a resposta em português gerada pela LLM.

---

## 📌 Conclusões e Aprendizados
* **Minimização de Latência:** Manter o loop de busca vetorial e junção de dados dentro da engine relacional reduz o tráfego de rede e o overhead de microsserviços intermediários.
* **Segurança Centralizada:** O uso de `DATABASE SCOPED CREDENTIAL` garante que chaves de API trafeguem apenas de forma criptografada dentro do perímetro controlado da nuvem, eliminando chaves expostas em códigos de aplicação.
