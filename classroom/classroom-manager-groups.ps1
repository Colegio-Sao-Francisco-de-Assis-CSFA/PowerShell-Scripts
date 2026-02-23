# Força o encoding UTF-8 com BOM para compatibilidade e limpa o terminal
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8BOM'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Clear-Host

<#
.SINOPSE
  Gerencia grupos de professores do Google Workspace a partir de um CSV.

.DESCRIÇÃO
  O script lê o arquivo classroom_manager.csv e, para cada linha:
  - Verifica se o grupo informado na coluna "teachergroup" existe no Google Workspace
  - Se existir, esvazia o grupo sincronizando com o grupo vazio@colsaofrancisco.com.br
  - Se não existir, cria o grupo com o nome "Professores - {name}"
    copiando as configurações do grupo padrao@colsaofrancisco.com.br

.EXEMPLO
  .\classroom-manager-groups.ps1

.NOTAS
  Autor: Diogo
  Criado em: 09/02/2026
  Atualizado em: 09/02/2026

  Changelog:
    - 09/02/2026 v1.0 - Criação do script
#>

# Caminho do CSV de entrada
$csvPath = "C:\Users\dnunes\Downloads\classroom_manager.csv"

# Grupo vazio utilizado para limpeza
$grupoVazio = "vazio@colsaofrancisco.com.br"

# Grupo modelo para copiar configurações
$grupoPadrao = "padrao-prof@colsaofrancisco.com.br"

# Importa o CSV
$dados = Import-Csv $csvPath

Write-Host "📄 Processando arquivo classroom_manager.csv..." -ForegroundColor Cyan
Write-Host ""

foreach ($linha in $dados) {

  # Lê os dados do CSV
  $teacherGroup = $linha.teachergroup
  $nomeGrupo = "Professores - $($linha.name)"

  Write-Host "🔍 Verificando grupo: $teacherGroup" -ForegroundColor Yellow

  # Verifica se o grupo existe no Google Workspace
  gam info group $teacherGroup *> $null
  $codigoSaida = $LASTEXITCODE

  if ($codigoSaida -eq 0) {

    # Grupo existe → esvaziar
    Write-Host "✅ Grupo encontrado. Esvaziando membros..." -ForegroundColor Green

    gam update group $teacherGroup sync members group $grupoVazio

    Write-Host "🧹 Grupo $teacherGroup esvaziado com sucesso." -ForegroundColor Green
    Write-Host ""

  }
  else {

    # Grupo não existe → criar
    Write-Host "❌ Grupo não encontrado. Criando novo grupo..." -ForegroundColor Red

    gam create group $teacherGroup `
      name "$nomeGrupo" `
      copyfrom $grupoPadrao

    Write-Host "🆕 Grupo $teacherGroup criado com sucesso." -ForegroundColor Green
    Write-Host ""

  }
}

Write-Host "✅ Processamento finalizado." -ForegroundColor Cyan
