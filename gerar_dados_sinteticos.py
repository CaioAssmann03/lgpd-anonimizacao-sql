"""
Gera a base sintetica da "Loja Aurora" (clientes, funcionarios, pedidos e
atendimentos), exporta em CSV/ e monta o banco SQLite a partir do esquema em
sql/01_schema.sql.

Nenhum dado aqui e' real. Nomes, CPFs, e-mails e telefones vem do Faker
(locale pt_BR), que gera CPFs com digito verificador valido mas totalmente
inventados: servem pra simular o formato, sem expor ninguem de verdade.
"""
import random
import sqlite3
from datetime import date
from pathlib import Path

import pandas as pd
from faker import Faker

SEED = 42
N_CLIENTES = 400
N_FUNCIONARIOS = 18
N_PEDIDOS = 1200
N_ATENDIMENTOS = 260

PASTA_PROJETO = Path(__file__).parent
PASTA_CSV = PASTA_PROJETO / "CSV"
CAMINHO_BANCO = PASTA_PROJETO / "banco_lgpd.db"
CAMINHO_SCHEMA = PASTA_PROJETO / "sql" / "01_schema.sql"

CARGOS_POR_DEPARTAMENTO = {
    "Atendimento": ["Atendente de Suporte", "Analista de Atendimento"],
    "Financeiro": ["Assistente Financeiro", "Analista Financeiro"],
    "Marketing": ["Analista de Marketing", "Coordenador de Marketing"],
    "Compliance": ["Analista de Dados", "DPO"],
}
FORMAS_PAGAMENTO = ["cartao_credito", "pix", "boleto"]
STATUS_PEDIDO = ["processando", "enviado", "entregue", "entregue", "entregue", "cancelado"]
CANAIS_ATENDIMENTO = ["chat", "telefone", "e-mail"]
ASSUNTOS_ATENDIMENTO = [
    "duvida sobre pedido",
    "troca de produto",
    "solicitacao de cancelamento",
    "problema no pagamento",
    "solicitacao de exclusao de dados (LGPD)",
]


def gerar_clientes(fake: Faker) -> pd.DataFrame:
    linhas = []
    for i in range(1, N_CLIENTES + 1):
        nascimento = fake.date_of_birth(minimum_age=18, maximum_age=80)
        cadastro = fake.date_between(start_date="-4y", end_date="today")
        linhas.append(
            {
                "id": i,
                "nome": fake.name(),
                "cpf": fake.cpf(),
                "email": fake.email(),
                "telefone": fake.cellphone_number(),
                "data_nascimento": nascimento.isoformat(),
                "cidade": fake.city(),
                "estado": fake.estado_sigla(),
                "data_cadastro": cadastro.isoformat(),
                "excluido_lgpd": 0,
            }
        )
    return pd.DataFrame(linhas)


def gerar_funcionarios(fake: Faker) -> pd.DataFrame:
    linhas = []
    departamentos = list(CARGOS_POR_DEPARTAMENTO.keys())
    for i in range(1, N_FUNCIONARIOS + 1):
        departamento = departamentos[(i - 1) % len(departamentos)]
        cargo = random.choice(CARGOS_POR_DEPARTAMENTO[departamento])
        linhas.append(
            {
                "id": i,
                "nome": fake.name(),
                "cargo": cargo,
                "departamento": departamento,
            }
        )
    return pd.DataFrame(linhas)


def gerar_pedidos(fake: Faker, ids_clientes: list[int]) -> pd.DataFrame:
    linhas = []
    for i in range(1, N_PEDIDOS + 1):
        linhas.append(
            {
                "id": i,
                "cliente_id": random.choice(ids_clientes),
                "data_pedido": fake.date_between(start_date="-2y", end_date="today").isoformat(),
                "valor": round(random.uniform(39.9, 1899.9), 2),
                "forma_pagamento": random.choice(FORMAS_PAGAMENTO),
                "status": random.choice(STATUS_PEDIDO),
            }
        )
    return pd.DataFrame(linhas)


def gerar_atendimentos(
    fake: Faker, ids_clientes: list[int], funcionarios_atendimento: list[int]
) -> pd.DataFrame:
    linhas = []
    for i in range(1, N_ATENDIMENTOS + 1):
        linhas.append(
            {
                "id": i,
                "cliente_id": random.choice(ids_clientes),
                "funcionario_id": random.choice(funcionarios_atendimento),
                "data_abertura": fake.date_between(start_date="-1y", end_date="today").isoformat(),
                "canal": random.choice(CANAIS_ATENDIMENTO),
                "assunto": random.choice(ASSUNTOS_ATENDIMENTO),
                "resolvido": random.choice([0, 1, 1]),
            }
        )
    return pd.DataFrame(linhas)


def montar_banco(clientes, funcionarios, pedidos, atendimentos) -> None:
    if CAMINHO_BANCO.exists():
        CAMINHO_BANCO.unlink()

    conexao = sqlite3.connect(CAMINHO_BANCO)
    conexao.executescript(CAMINHO_SCHEMA.read_text(encoding="utf-8"))

    clientes.to_sql("clientes", conexao, if_exists="append", index=False)
    funcionarios.to_sql("funcionarios", conexao, if_exists="append", index=False)
    pedidos.to_sql("pedidos", conexao, if_exists="append", index=False)
    atendimentos.to_sql("atendimentos", conexao, if_exists="append", index=False)

    conexao.commit()
    conexao.close()


def main() -> None:
    random.seed(SEED)
    fake = Faker("pt_BR")
    Faker.seed(SEED)

    PASTA_CSV.mkdir(exist_ok=True)

    clientes = gerar_clientes(fake)
    funcionarios = gerar_funcionarios(fake)
    ids_clientes = clientes["id"].tolist()
    funcionarios_atendimento = funcionarios.loc[
        funcionarios["departamento"] == "Atendimento", "id"
    ].tolist()
    pedidos = gerar_pedidos(fake, ids_clientes)
    atendimentos = gerar_atendimentos(fake, ids_clientes, funcionarios_atendimento)

    for nome, df in [
        ("clientes", clientes),
        ("funcionarios", funcionarios),
        ("pedidos", pedidos),
        ("atendimentos", atendimentos),
    ]:
        df.to_csv(PASTA_CSV / f"{nome}.csv", index=False, encoding="utf-8-sig")

    montar_banco(clientes, funcionarios, pedidos, atendimentos)

    print(f"Gerado: {len(clientes)} clientes, {len(funcionarios)} funcionarios, "
          f"{len(pedidos)} pedidos, {len(atendimentos)} atendimentos.")
    print(f"Banco criado em {CAMINHO_BANCO}")


if __name__ == "__main__":
    main()
