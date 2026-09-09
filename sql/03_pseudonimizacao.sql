-- Pseudonimizacao: substituir o identificador direto por um codigo que so'
-- pode ser revertido por quem tem acesso a uma tabela de mapeamento
-- separada (clientes_pseudonimo).
--
-- Por que nao e' so' um hash de CPF? Hash e' deterministico, e o CPF tem
-- so' 11 digitos: um atacante gera as ~10^11 combinacoes possiveis, compara
-- os hashes e descobre o CPF original em minutos (ataque de forca bruta por
-- baixa entropia da entrada, nao uma falha do algoritmo de hash). Isso vale
-- pra SHA-256 ou qualquer outro hash criptografico forte.
--
-- A alternativa e' uma chave substituta aleatoria, sem relacao matematica
-- com o CPF, guardada numa tabela separada com controle de acesso proprio.
-- Sem acesso a essa tabela, nao ha' como ligar o pseudo_id de volta ao
-- cliente. E' o padrao de pseudonimizacao que a ANPD reconhece como
-- efetivo (Guia de Anonimizacao da ANPD, 2022).

-- Popula o mapeamento (idempotente: so' insere quem ainda nao tem pseudo_id).
INSERT INTO clientes_pseudonimo (cliente_id, pseudo_id)
SELECT
    id,
    'CLI-' || upper(hex(randomblob(4)))
FROM clientes
WHERE id NOT IN (SELECT cliente_id FROM clientes_pseudonimo);

-- Uso: uma consulta analitica nunca precisa do nome nem do CPF, so' do
-- pseudo_id pra agrupar e comparar sem reidentificar ninguem.
SELECT
    cp.pseudo_id,
    c.cidade,
    c.estado,
    COUNT(p.id)   AS total_pedidos,
    SUM(p.valor)  AS valor_total
FROM clientes_pseudonimo cp
JOIN clientes c ON c.id = cp.cliente_id
JOIN pedidos p  ON p.cliente_id = c.id
GROUP BY cp.pseudo_id, c.cidade, c.estado
ORDER BY valor_total DESC
LIMIT 10;
