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