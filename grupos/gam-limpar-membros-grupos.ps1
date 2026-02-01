<#
.SINOPSE
  Limpa todos os membros de grupos utilizando GAM sync.

.DESCRIÇÃO
  O script solicita um arquivo CSV contendo uma única coluna chamada "email".
  Para cada grupo listado, os membros são sincronizados com o grupo
  vazio@colsaofrancisco.com.br utilizando o comando "gam sync group".
  Como o grupo de referência não possui membros, todos os participantes
  dos grupos de destino serão removidos.

.EXEMPLO
  # Limpa todos os membros dos grupos listados no CSV,
  # sincronizando-os com o grupo vazio@colsaofrancisco.com.br
  #
  .\gam-limpar-membros-grupos.ps1

.NOTAS
  Autor: Diogo
  Criado em: 31/01/2026
  Atualizado em: 31/01/2026

  Changelog:
    - 31/01/2026 v1.0 - Criação do script
#>

# Força o encoding UTF-8 com BOM para compatibilidade e limpa o terminal
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8BOM'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Clear-Host

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host " LIMPEZA DE MEMBROS DE GRUPOS (GAM SYNC) " -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "⚠️  ATENÇÃO:" -ForegroundColor Yellow
Write-Host "Este script REMOVE TODOS os membros dos grupos listados." -ForegroundColor Yellow
Write-Host "Grupo de referência (vazio): vazio@colsaofrancisco.com.br" -ForegroundColor Yellow
Write-Host ""

# Solicita o caminho do CSV
$csvPath = Read-Host "Informe o caminho completo do arquivo CSV"

# Valida se o arquivo existe
if (-not (Test-Path $csvPath)) {
  Write-Host "❌ Arquivo CSV não encontrado. Encerrando o script." -ForegroundColor Red
  exit
}

# Importa o CSV
$grupos = Import-Csv $csvPath

# Contadores para estatística
$total = 0
$sucesso = 0
$erro = 0

Write-Host ""
Write-Host "Iniciando limpeza dos grupos..." -ForegroundColor Yellow
Write-Host ""

foreach ($grupo in $grupos) {

  $total++
  $emailGrupo = $grupo.email.Trim()

  if ([string]::IsNullOrWhiteSpace($emailGrupo)) {
    Write-Host "⚠️  Linha $total ignorada (email vazio)." -ForegroundColor DarkYellow
    continue
  }

  Write-Host "[$total] Limpando grupo: $emailGrupo" -ForegroundColor Gray

  try {
    # Sincroniza os membros do grupo destino com o grupo vazio
    gam sync group $emailGrupo members group vazio@colsaofrancisco.com.br `
      > $null 2>&1

    Write-Host "   ✔ Grupo limpo com sucesso." -ForegroundColor Green
    $sucesso++
  }
  catch {
    Write-Host "   ❌ Erro ao limpar o grupo." -ForegroundColor Red
    $erro++
  }
}

# Resumo final
Write-Host ""
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host " RESUMO FINAL " -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "Total de grupos processados : $total"
Write-Host "Grupos limpos com sucesso   : $sucesso" -ForegroundColor Green
Write-Host "Erros                       : $erro" -ForegroundColor Red
Write-Host ""

Write-Host "Processo finalizado." -ForegroundColor Cyan
