-- Mascaramento: reduzir a exposicao de um dado sensivel sem descartar o
-- registro inteiro. O dado original continua existindo na tabela base; quem
-- consulta a versao mascarada e' que nao consegue reconstitui-lo.

-- CPF: mantem so' os 2 ultimos digitos. Sozinhos, nao identificam ninguem.
SELECT
    id,
    nome,
    cpf                                AS cpf_original,
    '***.***.***-' || substr(cpf, -2)  AS cpf_mascarado
FROM clientes
LIMIT 5;

-- E-mail: mantem a primeira letra do usuario e o dominio inteiro. O dominio
-- sozinho nao e' um dado pessoal.
SELECT
    id,
    email                                                        AS email_original,
    substr(email, 1, 1) || '***@' || substr(email, instr(email, '@') + 1) AS email_mascarado
FROM clientes
LIMIT 5;

-- Telefone: mantem so' os 4 ultimos digitos.
SELECT
    id,
    telefone                               AS telefone_original,
    '(**) *****-' || substr(telefone, -4)  AS telefone_mascarado
FROM clientes
LIMIT 5;

-- Data de nascimento: idade exata, cruzada com cidade, ajuda a reidentificar
-- alguem numa base pequena. Generalizar pra faixa etaria reduz esse risco
-- (principio de k-anonimato: quanto mais gente cai na mesma faixa, mais
-- dificil isolar uma pessoa so').
WITH idade_calculada AS (
    SELECT
        id,
        data_nascimento,
        CAST((julianday('now') - julianday(data_nascimento)) / 365.25 AS INTEGER) AS idade
    FROM clientes
)
SELECT
    id,
    data_nascimento,
    idade,
    CASE
        WHEN idade < 25 THEN '18-24'
        WHEN idade < 35 THEN '25-34'
        WHEN idade < 45 THEN '35-44'
        WHEN idade < 55 THEN '45-54'
        WHEN idade < 65 THEN '55-64'
        ELSE '65+'
    END AS faixa_etaria
FROM idade_calculada
LIMIT 5;
