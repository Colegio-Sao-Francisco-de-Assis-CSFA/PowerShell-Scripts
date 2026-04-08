# Contribuindo com o Projeto

Obrigado por considerar contribuir com este repositório.
Este projeto reúne scripts PowerShell voltados para administração, automação, Active Directory, Google Workspace via GAM, arquivos, fotos e rotinas operacionais.

Como parte do processo de publicação pública do repositório, toda contribuição deve priorizar segurança, clareza e padronização.

## Antes de contribuir

Antes de abrir um pull request, considere os pontos abaixo:

- revise se o script ou documentação não expõe caminhos locais, e-mails reais, nomes internos, OUs, IDs ou credenciais
- evite adicionar valores sensíveis diretamente no código
- use o arquivo `.env` para configurações locais e o `.env.example` como referência pública
- prefira mudanças pequenas e focadas, especialmente em scripts sensíveis

## Padrões obrigatórios do projeto

Todas as contribuições devem seguir estas diretrizes:

- idioma: português do Brasil (pt-BR)
- codificação: UTF-8 com BOM
- quebra de linha: CRLF
- indentação: 2 espaços
- mensagens e comentários claros
- output limpo no terminal

Todos os scripts PowerShell devem começar com este bloco:

```powershell
# Força o encoding UTF-8 com BOM para compatibilidade e limpa o terminal
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8BOM'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Clear-Host
```

## Cabeçalho padrão dos scripts

Todo script novo ou revisado deve conter cabeçalho no formato abaixo:

```powershell
<#
.SINOPSE
  [Resumo curto sobre o que o script faz.]
.INSTRUÇÕES
  [Instruções de utilização do script.]

.DESCRIÇÃO
  [Descrição detalhada do funcionamento e propósito.]

.EXEMPLO
  .\nomedoscript.ps1

.NOTAS
  Autor: Diogo Nunes
  Criado em: [DATA]
  Atualizado em: [DATA]

  Changelog:
    - [DATA] v1.0 - Criação do script
    - [DATA] v1.1 - Ajustes e melhorias
#>
```

## Segurança e sanitização

Como este repositório está sendo preparado para uso público, toda contribuição deve evitar:

- senhas no código
- tokens, chaves ou segredos
- caminhos pessoais como `C:\Users\...`
- caminhos internos fixos como `D:\Downloads` ou similares
- e-mails reais de usuários
- nomes internos da operação que não sejam necessários
- exemplos com dados reais

Sempre que possível:

- use dados fictícios em exemplos
- centralize configurações no `.env`
- valide entradas antes de executar ações destrutivas
- peça confirmação explícita em operações sensíveis

## Uso de `.env`

Configurações locais devem ficar no arquivo `.env`, que não deve ser versionado.
O arquivo `.env.example` deve permanecer atualizado para orientar novos usuários.

Exemplos de configurações que devem ir para o `.env`:

- diretório de logs
- executáveis externos como `gam`
- OUs e caminhos organizacionais
- domínios válidos

## Logs e arquivos temporários

Os scripts devem usar o diretório definido em `LOGS_DIR` no `.env`.
Ao adicionar ou revisar um script:

- não grave logs em caminhos fixos no código
- concentre logs e temporários no local configurado
- mantenha nomes de arquivos e pastas fáceis de identificar

## Dependências externas

Quando um script depender de ferramentas externas, isso deve ficar claro no próprio script e na documentação da pasta.

Exemplos:

- `GAM`
- módulo `ActiveDirectory`
- `ffmpeg`
- `yt-dlp`

Também é recomendável validar a presença dessas dependências antes da execução principal.

## Documentação

Ao criar ou alterar scripts:

- atualize o `README.md` da pasta correspondente, quando necessário
- revise o `README.md` principal se a mudança impactar a visão geral do repositório
- descreva claramente o objetivo, as dependências e o status do script

## Como contribuir

Fluxo recomendado:

1. Faça um fork do repositório.
2. Clone o fork para o seu ambiente local.
3. Crie uma branch específica para a alteração.
4. Faça mudanças pequenas e objetivas.
5. Teste manualmente o que foi alterado.
6. Revise se não há dados sensíveis no código ou na documentação.
7. Abra um pull request com uma descrição clara do que foi feito.

## Pull requests

Ao abrir um pull request, procure informar:

- o problema que está sendo resolvido
- quais arquivos foram alterados
- se houve mudança de comportamento
- dependências novas, se existirem
- riscos conhecidos ou pontos que ainda precisam de revisão

## Issues e sugestões

Se você encontrar um problema, tiver uma ideia de melhoria ou identificar algo sensível que precise ser sanitizado, abra uma issue descrevendo:

- o contexto
- o comportamento atual
- o comportamento esperado
- os riscos envolvidos, quando houver

Obrigado por contribuir para tornar este repositório mais seguro, organizado e útil.
