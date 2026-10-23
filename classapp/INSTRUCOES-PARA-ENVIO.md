# Envio de mensagens pelo ClassApp

## Instalação

Extraia os arquivos na pasta dos scripts, mantendo `classapp-comum.ps1` ao lado dos outros `.ps1`. Preserve seu `.env`; nenhum token está incluído no pacote.

Variáveis esperadas no `.env`:

```dotenv
CLASSAPP_TOKEN_TESTE=seu_token_de_teste
CLASSAPP_TOKEN_PRODUCAO=seu_token_de_producao
```

Não coloque comentários depois do valor. Aspas em volta do token são opcionais.

## Bases locais de alunos

- `dados/alunos-producao.json`: base padrão de produção, já preenchida com o JSON fornecido (584 cadastros).
- `dados/alunos-teste.json`: base independente do ambiente de teste; crie com `get-api-classapp.ps1 -Teste`.
- As bases são arrays JSON com os campos `fullname`, `eid` e `disabled`, além dos demais campos da exportação. Não edite os EIDs manualmente no arquivo: ajuste o cadastro no ClassApp e atualize a base.
- O get consulta a API uma vez e tenta baixar o mesmo arquivo até ficar disponível. Após validar o conteúdo, substitui a base do ambiente. Uma falha de download mantém a base anterior.

Atualizar produção (padrão):

```powershell
.\get-api-classapp.ps1
```

Atualizar testes:

```powershell
.\get-api-classapp.ps1 -Teste
```

A consulta pode gerar um e-mail de exportação do ClassApp. A base é uma fotografia do momento da consulta, não uma consulta em tempo real durante cada envio.

## Formato do CSV

Crie uma planilha e exporte como **CSV UTF-8**. Aceita `;` ou `,`. A primeira coluna deve ser `enviar`, e o cabeçalho deve estar na primeira linha, sem títulos acima.

| Coluna | Obrigatória | Conteúdo |
|---|---|---|
| enviar | Sim | SIM envia; NÃO, NAO ou vazio ignora a linha |
| nome | Sim | Nome completo do aluno como consta no JSON/ClassApp |
| assunto | Sim | Título da mensagem; aceita variáveis |
| mensagem | Sim | Texto simples; aceita variáveis e quebras de linha |
| tipo | Não | comunicado (padrão), academico, financeiro ou aviso |
| responder | Não | SIM (padrão) habilita respostas; NÃO bloqueia |
| Outras colunas | Não | Variáveis livres: link, pendencias, primeiro_nome etc. |

Não é preciso incluir EID no CSV. O script busca pelo nome completo. Ignora acentos, maiúsculas/minúsculas e espaços repetidos, mas não aceita nomes abreviados, parciais ou aproximados. Nome duplicado bloqueia o lote, mesmo se um cadastro estiver inativo: corrija a identificação com a escola antes de enviar.

Exemplo de CSV com ponto e vírgula (substitua o nome fictício por um cadastro real do ambiente):

```csv
enviar;nome;assunto;mensagem;tipo;responder;primeiro_nome;link
SIM;NOME COMPLETO DO ALUNO;Informações para {{primeiro_nome}};Olá, família de {{primeiro_nome}}! Acesse: {{link}};comunicado;SIM;Nome;https://example.com
```

As variáveis usam `{{coluna}}`. Cada variável precisa ter coluna e valor na mesma linha. Os valores são substituídos uma vez, sem executar código. Para mensagens diferentes, basta preencher um assunto e uma mensagem diferentes em cada linha. Você pode repetir o mesmo modelo nas linhas e variar apenas as colunas auxiliares.

Para Eurekas, use uma coluna `pendencias` com uma disciplina por linha, por exemplo:

```text
Língua Portuguesa: 5, 9, 10 e 11
Matemática: 10
História: 7, 8, 9 e 10
```

Na coluna mensagem, escreva o texto desejado e inclua `{{pendencias}}`. No Excel/Sheets, insira quebras de linha na célula; a exportação CSV coloca o campo entre aspas automaticamente. Não monte manualmente CSV com vírgulas/ponto e vírgula no conteúdo sem aspas. HTML não é necessário: o script protege o texto e converte as quebras de linha para o ClassApp.

## Uso

Conferir sem enviar (pede o caminho do CSV):

```powershell
.\enviar-mensagens-classapp.ps1
```

Enviar em teste (pede o caminho do CSV):

```powershell
.\enviar-mensagens-classapp.ps1 -Enviar
```

Por padrão, o envio usa **somente token e base de teste**. Não troca para produção se o token/base de teste estiver ausente. O CSV de teste deve usar os nomes dos cadastros de teste (ex.: PHELLIPE e ANDRÉ); para simular nomes reais no texto, use outra coluna, como `nome_exibicao`.

Opcionalmente informe o caminho diretamente:

```powershell
.\enviar-mensagens-classapp.ps1 -Csv 'C:\Projetos\Scripts\classapp\mensagens.csv'
```

Produção exige uma opção explícita. Para apenas validar os nomes contra a base de produção, sem enviar:

```powershell
.\enviar-mensagens-classapp.ps1 -Producao
```

Somente quando quiser disparar mensagens reais, use ambas as opções:

```powershell
.\enviar-mensagens-classapp.ps1 -Producao -Enviar
```

O remetente continua sendo o perfil vinculado ao token. Para enviar como canal, é preciso o token emitido pelo ClassApp para esse remetente.

## Validação antes dos envios

O script verifica **todas as linhas SIM antes da primeira chamada de envio**. Bloqueia o lote inteiro se houver nome ausente ou duplicado, aluno inativo, EID vazio ou duplicado, variável ausente, conteúdo vazio ou tipo inválido. Para problemas na base, rode o get do ambiente correspondente e execute o envio novamente. Se persistir, corrija o nome no CSV ou o cadastro no ClassApp. Linhas NÃO não são validadas nem enviadas.

O lote inteiro só é enviado após passar pela validação. A API pode falhar durante o envio; nesse caso, a execução para e mensagens anteriores podem já ter sido aceitas. Não há repetição automática de requisições POST.

O histórico `logs/historico-<ambiente>.csv` registra tentativas e respostas HTTP. HTTP de sucesso sem `broker_message_id` não interrompe o lote, mas não comprova entrega. Confira o recebimento no ClassApp.

Uma mensagem idêntica já tentada no mesmo ambiente bloqueia a próxima execução inteira. Marque as linhas já processadas como NÃO para continuar com as demais. Para tentativas inconclusivas, confira primeiro o ClassApp; só remova os registros do hash correspondente no histórico se tiver certeza de que o envio não ocorreu e quiser tentar novamente. Não apague todo o histórico. Dois processos de envio no mesmo ambiente não podem rodar ao mesmo tempo.

## Git

O `.gitignore` incluído ignora `.env`, JSONs, históricos e os CSVs de envio. Apenas scripts, instruções e exemplos sem dados pessoais devem ser versionados. Se já existir um `.gitignore`, acrescente estas regras a ele.

Se dados ou `.env` já estavam rastreados, o ignore sozinho não basta. Para parar de rastrear mantendo os arquivos locais, execute apenas para caminhos que existam no seu repositório:

```powershell
git rm --cached -- .env
git rm -r --cached -- dados logs
```

Para um JSON antigo na raiz: `git rm --cached -- nome-do-arquivo.json`. Isso não remove versões já presentes no histórico do Git.

## Compatibilidade

Arquivos `.ps1` em UTF-8 com BOM, para Windows PowerShell 5.1 e PowerShell 7. Sem módulos externos. Não execute os scripts antigos junto com estes; use apenas o novo script de envio para os próximos lotes. O histórico desta versão não conhece os envios feitos pelos scripts antigos: marque essas linhas como NÃO no CSV.
