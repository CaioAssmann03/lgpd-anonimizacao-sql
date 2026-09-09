-- Esquema da base "Loja Aurora", uma varejista online ficticia.
-- Serve de cenario pra aplicar controles de LGPD sobre dados que ja nascem
-- identificaveis (nome, CPF, e-mail, telefone), como acontece em qualquer
-- sistema real de vendas.

PRAGMA foreign_keys = ON;

CREATE TABLE clientes (
    id              INTEGER PRIMARY KEY,
    nome            TEXT NOT NULL,
    cpf             TEXT NOT NULL UNIQUE,
    email           TEXT NOT NULL,
    telefone        TEXT NOT NULL,
    data_nascimento DATE NOT NULL,
    cidade          TEXT NOT NULL,
    estado          TEXT NOT NULL,
    data_cadastro   DATE NOT NULL,
    excluido_lgpd   INTEGER NOT NULL DEFAULT 0 CHECK (excluido_lgpd IN (0, 1))
);

CREATE TABLE funcionarios (
    id            INTEGER PRIMARY KEY,
    nome          TEXT NOT NULL,
    cargo         TEXT NOT NULL,
    departamento  TEXT NOT NULL CHECK (departamento IN ('Atendimento', 'Financeiro', 'Marketing', 'Compliance'))
);

CREATE TABLE pedidos (
    id              INTEGER PRIMARY KEY,
    cliente_id      INTEGER NOT NULL REFERENCES clientes(id),
    data_pedido     DATE NOT NULL,
    valor           REAL NOT NULL,
    forma_pagamento TEXT NOT NULL,
    status          TEXT NOT NULL CHECK (status IN ('processando', 'enviado', 'entregue', 'cancelado'))
);

CREATE TABLE atendimentos (
    id              INTEGER PRIMARY KEY,
    cliente_id      INTEGER NOT NULL REFERENCES clientes(id),
    funcionario_id  INTEGER NOT NULL REFERENCES funcionarios(id),
    data_abertura   DATE NOT NULL,
    canal           TEXT NOT NULL CHECK (canal IN ('chat', 'telefone', 'e-mail')),
    assunto         TEXT NOT NULL,
    resolvido       INTEGER NOT NULL DEFAULT 0 CHECK (resolvido IN (0, 1))
);

-- Tabela de mapeamento de pseudonimo. Fica separada das demais de proposito:
-- o controle de acesso a ESTA tabela e' o que garante a pseudonimizacao (ver
-- 03_pseudonimizacao.sql pra explicacao de por que nao e' so um hash de CPF).
CREATE TABLE clientes_pseudonimo (
    cliente_id  INTEGER PRIMARY KEY REFERENCES clientes(id),
    pseudo_id   TEXT NOT NULL UNIQUE
);

-- Trilha de auditoria: quem consultou dado sensivel de qual cliente, e por
-- qual view (i.e., com qual nivel de mascaramento). E' o registro que a LGPD
-- chama de "prestacao de contas" (accountability).
CREATE TABLE log_acesso_dados (
    id              INTEGER PRIMARY KEY,
    funcionario_id  INTEGER NOT NULL REFERENCES funcionarios(id),
    cliente_id      INTEGER NOT NULL REFERENCES clientes(id),
    view_utilizada  TEXT NOT NULL,
    data_acesso     TEXT NOT NULL DEFAULT (datetime('now'))
);
