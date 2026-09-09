# LGPD em SQL: mascaramento, pseudonimização e governança de acesso

Base sintética de uma loja virtual fictícia (Loja Aurora), com controles de LGPD
implementados direto no banco: mascaramento de CPF/e-mail/telefone, pseudonimização,
views por papel de acesso e um fluxo de direito ao esquecimento.

A pergunta que guiou o projeto: dá para aplicar controles reais de LGPD sem sair do SQL,
de um jeito que sobreviva a uma auditoria?

---

## O cenário

Simulei o banco operacional de uma loja virtual: 400 clientes, 1.200 pedidos, 260
atendimentos de suporte e 18 funcionários distribuídos em Atendimento, Financeiro,
Marketing e Compliance. Todo dado é sintético, gerado com Faker (locale pt_BR). Os CPFs
têm dígito verificador válido, mas não pertencem a ninguém.

## Modelagem

5 tabelas operacionais (`clientes`, `funcionarios`, `pedidos`, `atendimentos`) mais duas
de suporte à governança: `clientes_pseudonimo` (mapeamento de pseudônimo, guardado à
parte) e `log_acesso_dados` (trilha de auditoria). Esquema completo em
[`sql/01_schema.sql`](sql/01_schema.sql).

## Técnicas aplicadas

**1. Mascaramento** — [`sql/02_mascaramento.sql`](sql/02_mascaramento.sql)
CPF mostra só os 2 últimos dígitos, e-mail mostra só a primeira letra e o domínio,
telefone mostra só os 4 últimos dígitos. Data de nascimento vira faixa etária (princípio
de k-anonimato: quanto mais gente cai na mesma faixa, mais difícil isolar uma pessoa só).

**2. Pseudonimização** — [`sql/03_pseudonimizacao.sql`](sql/03_pseudonimizacao.sql)
O ponto técnico central do projeto: hashear o CPF não é pseudonimização segura. CPF tem
11 dígitos, então um hash determinístico, mesmo SHA-256, é quebrável por força bruta em
minutos, testando as ~10^11 combinações possíveis. Por isso usei uma chave substituta
aleatória (`CLI-XXXXXXXX`), sem relação matemática com o CPF, guardada numa tabela
separada. Sem acesso a essa tabela, não dá pra religar o pseudônimo ao cliente.

**3. Views por papel de acesso** — [`sql/04_views_por_papel.sql`](sql/04_views_por_papel.sql)
4 views, uma por perfil: Atendimento (contato mascarado), Financeiro (CPF integral,
porque nota fiscal exige, mas contato mascarado), Marketing (nem nome, nem CPF, nem
contato, só pseudônimo + cidade/estado + faixa etária) e DPO (não vê dado de cliente, vê
o log de quem acessou o quê). Ninguém consulta a tabela `clientes` direto.

**4. Direito ao esquecimento** — [`sql/05_direito_ao_esquecimento.sql`](sql/05_direito_ao_esquecimento.sql)
Um pedido de exclusão não apaga a linha, porque pedidos têm retenção fiscal obrigatória.
O cadastro é anonimizado em cima (nome, CPF, e-mail e telefone viram valores genéricos) e
o histórico de pedidos continua existindo, mas sem identificar mais ninguém.

## Como reproduzir

```bash
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
python gerar_dados_sinteticos.py
```

Isso gera os CSVs em `CSV/` e monta `banco_lgpd.db`. Depois é só abrir o banco no DB
Browser for SQLite e rodar os arquivos de `sql/` em ordem (02 a 05; o 01 já roda sozinho
dentro do `gerar_dados_sinteticos.py`).

## Aprendizados

- Hash não é sinônimo de pseudonimização quando o dado de entrada tem baixa entropia.
  Foi o achado técnico mais forte do projeto, e não estava no plano original: a ideia
  inicial do roadmap era só "mascarar CPF/e-mail via SQL".
- SQL puro não dispara nada em cima de um SELECT. Um log de acesso de verdade precisa de
  instrumentação na camada de aplicação, não só do banco. Preferi documentar essa
  limitação a fingir que a trilha de auditoria roda sozinha.

## Limitações conhecidas

- `log_acesso_dados` é alimentado com INSERTs de exemplo, simulando o que uma aplicação
  registraria a cada consulta feita por uma das views. Não existe automatização real
  disso disparada por SELECT, porque nenhum banco relacional dispara trigger em leitura.
- Dado sintético (Faker), não uma base real de clientes. Isso é intencional: dado real de
  cliente não deveria circular num repositório público de portfólio, então a mesma lógica
  de anonimização é aplicada aqui a um cenário simulado.
- Sem dashboard em Power BI ou Excel neste projeto. Decisão deliberada para priorizar o
  fechamento de lacunas em SQL, Python e LGPD.
