

      -- ######################################################
  -- ##### Consultas para Challenge Engineer       -- #####
  -- ##### Autor: Plínio Nunes Torres Junior       -- #####
  -- ##### Data Criação: 14/07/2024                -- #####
  -- ##### Data Ültima Alteração: 14/07/2024       -- #####
  -- ##### IDe Utilziada: Big Query                -- #####
  -- ######################################################

  -- ##############################################################################
  -- ##### Por cada mes del 2020, se solicita el top 5 de                  -- #####
  -- ##### usuarios que más vendieron($) en la categoría Celulares.        -- ##### 
  -- ##### Se requiere el mes y año de análisis, nombre y apellido         -- #####
  -- ##### del vendedor, cantidad de ventas realizadas,                    -- #####
  -- ##### cantidad de productos vendidos y el monto total transaccionado. -- #####
  -- ##############################################################################
SELECT 
ORDERS.DATA_CRIACAO,
  ORDERS.ID_CUSTOMER_SEL,
  CONCAT(SEL.NOME, " ", SOBRENOME) AS NOME_SOBRENOME,
  ORDERS.VALOR_TOTAL,
  ORDERS.TOTAL_VENDAS
FROM (

  -- Criação de Ranking para eleger os 5 principais vendedores do mês
  SELECT
    ROW_NUMBER() OVER(PARTITION BY DATA_CRIACAO ORDER BY DATA_CRIACAO, VALOR_TOTAL DESC) AS RANKING,
    ID_CUSTOMER_SEL,
    DATA_CRIACAO,
    VALOR_TOTAL,
    TOTAL_VENDAS
  FROM (
    SELECT
      FORMAT_DATE('%Y%m',DATA_CRIACAO) AS DATA_CRIACAO,
      ID_CUSTOMER_SEL,
      SUM(VALOR_TOTAL) AS VALOR_TOTAL,
      COUNT(DISTINCT ID_ORDER ) AS TOTAL_VENDAS
    FROM
      ORDERS_TABLE AS ORD
      INNER JOIN  CATEGORIA_TABLE AS CAT ON (ORD.CODIGO_CATEGORIA_L3 = CAT.CODIGO_CATEGORIA_L3)
    WHERE DATA_CANCELAMENTO IS NULL
    AND DATA_CRIACAO BETWEEN '2020-01-01'
      AND '2020-12-31'
      AND UPPER(NOME_CATEGORIA_L3) LIKE ('%CELULAR%')
    GROUP BY
      1,
      2
    ORDER BY
      1,
      3 DESC)) ORDERS
      INNER JOIN CUSTOMER_TABLE SEL ON (ORDERS.ID_CUSTOMER_SEL = SEL.ID_CUSTOMER )
WHERE
  RANKING BETWEEN 1
  AND 5;


  -- ######################################################
  -- ##### Consultas para Challenge Engineer       -- #####
  -- ##### Autor: Plínio Nunes Torres Junior       -- #####
  -- ##### Data Criação: 14/07/2024                -- #####
  -- ##### Data Ültima Alteração: 14/07/2024       -- #####
  -- ##### IDe Utilziada: Big Query                -- #####
  -- ######################################################
  
  -- ######################################################
  -- ##### Lista de vendedores que fazem           -- #####
  -- ##### aniversário na data autal e com vendas  -- #####
  -- ##### em janeiro superior a 1500              -- #####
  -- ######################################################
SELECT
  CUST.ID_CUSTOMER
FROM
  CUSTOMER_TABLE AS CUST
INNER JOIN (
  SELECT
    ID_CUSTOMER_SEL,
    COUNT(DISTINCT ID_ORDER) AS TOTAL_ORDERS
  FROM
    ORDERS_TABLE
  WHERE
    DATA_CRIACAO BETWEEN '2020-01-01'
    AND '2020-01-31'
    AND DATA_CANCELAMENTO IS NULL
  GROUP BY
    1
  HAVING
    COUNT(DISTINCT ID_ORDER) > 1500 ) ORD
ON
  (ORD.ID_CUSTOMER_SEL = CUST.ID_CUSTOMER)
WHERE
  DATA_NASCIMENTO = CURRENT_DATE();



  -- ######################################################
  -- ##### Consultas para Challenge Engineer       -- #####
  -- ##### Autor: Plínio Nunes Torres Junior       -- #####
  -- ##### Data Criação: 14/07/2024                -- #####
  -- ##### Data Ültima Alteração: 14/07/2024       -- #####
  -- ##### IDe Utilziada: Big Query                -- #####
  -- ######################################################

  -- ##########################################################################################################################
  -- #####Se solicita poblar una nueva tabla con el precio y estado de los Ítems a fin del día.                        -- #####
  -- #####Tener en cuenta que debe ser reprocesable.                                                                   -- ##### 
  -- #####Vale resaltar que en la tabla Item, vamos a tener únicamente el último estado informado por la PK definida.  -- #####
  -- ##########################################################################################################################

-- Criaco de tabela temporaria para receber as novidades.

CREATE OR REPLACE TABLE ITEM_PH_TEMP AS ( 

SELECT 
    PHOTO_DATE,
    ID_ITEM,
    ID_SITE,
    ID_VARIACAO,
    NOME_ITEM,
    DATA_CRIACAO,
    DATA_DESATIVACAO,
    DATA_ATUALIZACAO,
    STATUS_ITEM,
    CODIGO_CATEGORIA_L3,
    VALOR_ITEM,
    CONDICAO_ITEM,
    MARCA,
    MODELO,
    PESO

FROM ITEM_PH_TABLE
WHERE COALESCE(DATA_ATUALIZACAO,PHOTO_DATE) = DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)

);

 -- Validacao para verificar se houve novidade para os itens

MERGE ITEM_TABLE PROD
USING ITEM_PH_TEMP STG
ON PROD.ID_ITEM = STG.ID_ITEM
AND PROD.ID_VARIACAO = STG.ID_VARIACAO
AND PROD.ID_SITE = STG.ID_SITE

 -- Caso seja um item novo ou receba novidade, realiza insercao

WHEN NOT MATCHED THEN 
INSERT (
    ID_ITEM,
    ID_SITE,
    ID_VARIACAO,
    NOME_ITEM,
    DATA_CRIACAO,
    DATA_DESATIVACAO,
    DATA_ATUALIZACAO,
    STATUS_ITEM,
    CODIGO_CATEGORIA_L3,
    VALOR_ITEM,
    CONDICAO_ITEM,
    MARCA,
    MODELO,
    PESO
)
VALUES (
    STG.ID_ITEM,
    STG.ID_SITE,
    STG.ID_VARIACAO,
    STG.NOME_ITEM,
    STG.DATA_CRIACAO,
    STG.DATA_DESATIVACAO,
    STG.PHOTO_DATE,
    STG.STATUS_ITEM,
    STG.CODIGO_CATEGORIA_L3,
    STG.VALOR_ITEM,
    STG.CONDICAO_ITEM,
    STG.MARCA,
    STG.MODELO,
    STG.PESO
)

 -- Caso não seja um item novo ou não receba novidade, mantém os mesmos dados

  WHEN MATCHED THEN
UPDATE SET 
    PROD.ID_ITEM = STG.ID_ITEM,
    PROD.ID_SITE = STG.ID_SITE,
    PROD.ID_VARIACAO = STG.ID_VARIACAO,
    PROD.NOME_ITEM = STG.NOME_ITEM,
    PROD.DATA_CRIACAO = STG.DATA_CRIACAO,
    PROD.DATA_DESATIVACAO = STG.DATA_DESATIVACAO,
    PROD.DATA_ATUALIZACAO = STG.DATA_ATUALIZACAO,
    PROD.STATUS_ITEM = STG.STATUS_ITEM,
    PROD.CODIGO_CATEGORIA_L3 = STG.CODIGO_CATEGORIA_L3,
    PROD.VALOR_ITEM = STG.VALOR_ITEM,
    PROD.CONDICAO_ITEM = STG.CONDICAO_ITEM,
    PROD.MARCA = STG.MARCA,
    PROD.MODELO = STG.MODELO,
    PROD.PESO = STG.PESO
;