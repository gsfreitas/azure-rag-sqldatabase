-- 1. REGISTRAR O MODELO EXTERNO DE EMBEDDINGS
CREATE EXTERNAL MODEL MyEmbeddingModel
WITH (
    LOCATION = '{URL_DE_DESTINO_AQUI}',
    API_FORMAT = 'Azure OpenAI',
    MODEL_TYPE = EMBEDDINGS,
    MODEL = '{SEU_MODELO}',
    CREDENTIAL = [URL_BASE]
);
GO

-- 2. MODELAGEM DAS TABELAS
CREATE TABLE documentos (
    id INT IDENTITY(1,1) PRIMARY KEY,
    conteudo NVARCHAR(MAX)
);
GO

CREATE TABLE documentos_embeddings (
    id INT IDENTITY(1,1) PRIMARY KEY,
    chunk_text NVARCHAR(MAX),
    vetor VECTOR(1536)
);
GO

-- 3. INGESTÃO DE DADOS BRUTOS
INSERT INTO documentos (conteudo) VALUES
(N'O Autonomous Database da Oracle permite consultas em linguagem natural via Select AI.'),
(N'Azure SQL Database suporta busca vetorial nativa com o tipo VECTOR e AI_GENERATE_EMBEDDINGS.'),
(N'Embeddings transformam texto em vetores numéricos que capturam significado semântico.'),
(N'RAG combina busca por similaridade com geração de texto por um modelo de linguagem.');
(N'Para redefinir sua senha no sistema corporativo, o colaborador deve acessar o portal 
de Identidade e clicar em Esqueci minha senha. O código de verificação será enviado exclusivamente 
para o celular cadastrado via SMS. Caso o usuário mude de aparelho ou perca o acesso ao dispositivo, 
ele precisará abrir um chamado diretamente com a equipe de suporte.')
GO

-- 4. ESTEIRA AUTOMATIZADA: CHUNKING + VECTOR GENERATION INLINE
INSERT INTO documentos_embeddings (chunk_text, vetor)
SELECT c.chunk,
       AI_GENERATE_EMBEDDINGS(c.chunk USE MODEL MyEmbeddingModel)
FROM documentos AS d
CROSS APPLY AI_GENERATE_CHUNKS(
    SOURCE = d.conteudo, CHUNK_TYPE = FIXED, CHUNK_SIZE = 100
) AS c;
GO