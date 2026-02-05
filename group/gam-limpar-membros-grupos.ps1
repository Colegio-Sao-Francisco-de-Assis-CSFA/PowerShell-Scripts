<#
.SINOPSE
  Limpa todos os membros de grupos utilizando sincronização via GAM.

.DESCRIÇÃO
  O script solicita um arquivo CSV contendo uma única coluna chamada "email".
  Para cada grupo listado, os membros são sincronizados com o grupo
  vazio@colsaofrancisco.com.br utilizando o comando:

    gam update group <grupo_destino> sync members group <grupo_referencia>

  Como o grupo de referência não possui membros, todos os participantes
  dos grupos de destino serão removidos.

.EXEMPLO
  # CSV de entrada (uma única coluna chamada "email"):
  #
  # email
  # turma1@colsaofrancisco.com.br
  # turma2@aluno.colsaofrancisco.com.br
  #
  # Execução do script:
  .\gam-limpar-membros-grupos.ps1

.NOTAS
  Autor: Diogo
  Criado em: 31/01/2026
  Atualizado em: 02/02/2026

  Changelog:
    - 31/01/2026 v1.0 - Criação do script
    - 02/02/2026 v1.1 - Correção do comando GAM e tratamento adequado do output
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
  exit 1
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

  # Monta os argumentos corretos do GAM
  $arguments = @(
    "update"
    "group"
    $emailGrupo
    "sync"
    "members"
    "group"
    "vazio@colsaofrancisco.com.br"
  )

  # Executa o GAM capturando stdout e stderr
  $process = Start-Process `
    -FilePath "gam" `
    -ArgumentList $arguments `
    -NoNewWindow `
    -RedirectStandardOutput "$env:TEMP\gam_stdout.txt" `
    -RedirectStandardError "$env:TEMP\gam_stderr.txt" `
    -PassThru `
    -Wait

  $stdout = Get-Content "$env:TEMP\gam_stdout.txt" -Raw
  $stderr = Get-Content "$env:TEMP\gam_stderr.txt" -Raw

  if ($process.ExitCode -eq 0) {

    # Extrai números do stdout do GAM
    $removed = ($stdout | Select-String 'Remove (\d+) Members').Matches.Groups[1].Value
    $added = ($stdout | Select-String 'Add (\d+) Members').Matches.Groups[1].Value

    if (-not $removed) { $removed = 0 }
    if (-not $added) { $added = 0 }

    Write-Host "   ✔ Grupo limpo com sucesso." -ForegroundColor Green
    Write-Host "     Membros removidos : $removed"
    Write-Host "     Membros adicionados: $added"

    $sucesso++
  }
  else {
    Write-Host "   ❌ Erro ao limpar o grupo." -ForegroundColor Red
    Write-Host "   Código de saída do GAM: $($process.ExitCode)" -ForegroundColor Red

    if (-not [string]::IsNullOrWhiteSpace($stderr)) {
      Write-Host "   Detalhes do erro:" -ForegroundColor DarkRed
      Write-Host "   $stderr"
    }

    $erro++
  }

  # Remove arquivos temporários
  Remove-Item "$env:TEMP\gam_stdout.txt", "$env:TEMP\gam_stderr.txt" -ErrorAction SilentlyContinue
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
