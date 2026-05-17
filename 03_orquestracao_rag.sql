-- 1. PIPELINE DE ORQUESTRACAO RAG COMPLETA (RETRIEVAL + GENERATION)

-- Defina a pergunta do usuário aqui
DECLARE @pergunta NVARCHAR(MAX) = N'o que eu faço se perder o meu celular para resetar a senha?';

-- Etapa A: Conversão da Pergunta em Vetor
DECLARE @qv VECTOR(1536) = AI_GENERATE_EMBEDDINGS(@pergunta USE MODEL MyEmbeddingModel);

-- Etapa B: Busca Vetorial Top 3 e Agregação de Contexto
DECLARE @contexto NVARCHAR(MAX);
SELECT @contexto = STRING_AGG(chunk_text, ' | ')
FROM (
    SELECT TOP (3) chunk_text
    FROM documentos_embeddings
    ORDER BY VECTOR_DISTANCE('cosine', @qv, vetor)
) t;

-- Etapa C: Construção de Prompt Estruturado em JSON
DECLARE @payload NVARCHAR(MAX) = JSON_OBJECT(
    'messages': JSON_ARRAY(
        JSON_OBJECT('role':'system','content':'Responda em português, apenas com base no contexto fornecido. Se o contexto não tiver a resposta, diga que não há informação suficiente.'),
        JSON_OBJECT('role':'user','content': @pergunta + ' Contexto: ' + @contexto)
    )
);

-- Etapa D: Inferência via Chamada REST Nativa para o GPT-4o
DECLARE @resp NVARCHAR(MAX);
EXEC sp_invoke_external_rest_endpoint
    @url = 'URL_DE_DESTINO',
    @method = 'POST',
    @credential = [CREDENCIAL_DO_MODELO],
    @payload = @payload,
    @response = @resp OUTPUT;

-- Etapa E: Extração e Exibição do Resultado Limpo
SELECT @contexto AS contexto_recuperado,
       JSON_VALUE(@resp, '$.result.choices[0].message.content') AS resposta_ia;
GO