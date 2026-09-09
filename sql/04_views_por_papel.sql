-- Views por papel de acesso: cada area da empresa enxerga so' o que precisa
-- pra fazer o trabalho dela (minimizacao de dados, LGPD art. 6, III).
-- Ninguem consulta a tabela "clientes" direto; todo acesso passa por uma
-- destas views. Rodar depois de 03_pseudonimizacao.sql (view de marketing
-- depende da tabela clientes_pseudonimo ja' populada).

DROP VIEW IF EXISTS view_atendimento;
CREATE VIEW view_atendimento AS
SELECT
    c.id,
    c.nome,
    '***.***.***-' || substr(c.cpf, -2)                                       AS cpf,
    substr(c.email, 1, 1) || '***@' || substr(c.email, instr(c.email, '@') + 1) AS email,
    '(**) *****-' || substr(c.telefone, -4)                                   AS telefone,
    c.cidade,
    c.estado
FROM clientes c
WHERE c.excluido_lgpd = 0;
-- Atendimento acha o cliente pelo nome e confirma contato, mas nao precisa
-- do CPF nem do e-mail/telefone completos pra isso.

DROP VIEW IF EXISTS view_financeiro;
CREATE VIEW view_financeiro AS
SELECT
    c.id,
    c.nome,
    c.cpf,                                                                     -- integral: exigido em nota fiscal
    substr(c.email, 1, 1) || '***@' || substr(c.email, instr(c.email, '@') + 1) AS email,
    '(**) *****-' || substr(c.telefone, -4)                                   AS telefone,
    c.cidade,
    c.estado
FROM clientes c
WHERE c.excluido_lgpd = 0;
-- Financeiro precisa do CPF integral porque emissao de nota fiscal e'
-- obrigacao legal (base legal do art. 7, II da LGPD). Contato, no entanto,
-- fica mascarado, porque financeiro nao usa isso pra falar com o cliente.

DROP VIEW IF EXISTS view_marketing_analytics;
CREATE VIEW view_marketing_analytics AS
SELECT
    pseudo_id,
    cidade,
    estado,
    CASE
        WHEN idade < 25 THEN '18-24'
        WHEN idade < 35 THEN '25-34'
        WHEN idade < 45 THEN '35-44'
        WHEN idade < 55 THEN '45-54'
        WHEN idade < 65 THEN '55-64'
        ELSE '65+'
    END AS faixa_etaria
FROM (
    SELECT
        cp.pseudo_id,
        c.cidade,
        c.estado,
        CAST((julianday('now') - julianday(c.data_nascimento)) / 365.25 AS INTEGER) AS idade
    FROM clientes c
    JOIN clientes_pseudonimo cp ON cp.cliente_id = c.id
    WHERE c.excluido_lgpd = 0
);
-- Marketing nao ve' nome, CPF nem contato: so' pseudo_id e atributos de
-- segmentacao. Pra decidir "campanha X performa melhor na faixa 25-34 de
-- SP" ninguem precisa saber quem, especificamente, e' cada pessoa da
-- amostra.

DROP VIEW IF EXISTS view_dpo_auditoria;
CREATE VIEW view_dpo_auditoria AS
SELECT
    l.id,
    f.nome         AS funcionario,
    f.departamento,
    l.cliente_id,
    l.view_utilizada,
    l.data_acesso
FROM log_acesso_dados l
JOIN funcionarios f ON f.id = l.funcionario_id
ORDER BY l.data_acesso DESC;
-- O DPO nao consulta dado de cliente por aqui: consulta QUEM acessou o que
-- e quando. E' o registro de accountability que a LGPD exige (art. 6, X).
-- Nota tecnica: SQL puro nao dispara trigger em SELECT (nenhum banco
-- relacional faz isso nativamente), entao esse log e' alimentado pela
-- camada de aplicacao a cada consulta feita por uma das views acima. Aqui
-- ele e' simulado com os INSERTs de exemplo abaixo.

INSERT INTO log_acesso_dados (funcionario_id, cliente_id, view_utilizada, data_acesso) VALUES
    (1, 12, 'view_atendimento', '2026-09-01 09:14:00'),
    (1, 47, 'view_atendimento', '2026-09-01 09:22:00'),
    (6, 12, 'view_financeiro',  '2026-09-01 11:03:00'),
    (3, 200, 'view_marketing_analytics', '2026-09-02 15:40:00');

SELECT * FROM view_dpo_auditoria;
