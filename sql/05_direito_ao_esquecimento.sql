-- Direito ao esquecimento (LGPD art. 18, VI): o titular pode pedir a
-- exclusao dos seus dados pessoais. A empresa nao pode simplesmente fazer
-- DELETE na linha, porque pedidos tem retencao fiscal obrigatoria por outra
-- legislacao (ate' 5 anos, a depender do tributo). A saida e' anonimizar o
-- CADASTRO e manter o HISTORICO TRANSACIONAL vinculado so' a um registro
-- que nao identifica mais ninguem.

-- Simula um pedido de exclusao do cliente de id = 7.
UPDATE clientes
SET
    nome     = 'CLIENTE EXCLUIDO',
    cpf      = '000.000.000-00',
    email    = 'excluido@anonimizado.local',
    telefone = '(00) 00000-0000',
    excluido_lgpd = 1
WHERE id = 7;
-- data_nascimento, cidade e estado ficam como estavam: sozinhos, numa base
-- de 400 clientes, nao reidentificam ninguem, e continuam uteis pra
-- estatistica agregada (por isso view_marketing_analytics ja' filtra
-- excluido_lgpd = 0 nas demais consultas, mas o registro em si permanece
-- utilizavel pra quem tem base legal de reter o historico).

-- Pedidos NAO sao apagados: continuam existindo pra contabilidade e
-- auditoria fiscal, mas agora so' referenciam um cadastro anonimo.
SELECT p.id, p.data_pedido, p.valor, c.nome, c.cpf
FROM pedidos p
JOIN clientes c ON c.id = p.cliente_id
WHERE p.cliente_id = 7;

-- Visao geral de todos os cadastros ja' anonimizados por pedido de exclusao.
SELECT id, nome, cpf, email, telefone, excluido_lgpd
FROM clientes
WHERE excluido_lgpd = 1;

-- Toda view construida em 04_views_por_papel.sql ja' filtra
-- "excluido_lgpd = 0", entao um cliente que pediu exclusao some das
-- consultas de atendimento, financeiro e marketing automaticamente, sem
-- precisar editar as views de novo a cada pedido.
