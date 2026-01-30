<#
.SINOPSE
  Adiciona os administradores responsáveis em todas as turmas do Google Classroom.

.DESCRIÇÃO
  Este script lê um arquivo CSV com as turmas e adiciona os administradores definidos
  na variável de ambiente ADMINS como co-professores em cada curso do Google Classroom,
  utilizando comandos GAM.

.EXEMPLO
  .\classroom-manager-adms.ps1

.NOTAS
  Autor: Diogo
  Atualizado em: 22/04/2025

  Changelog:
    - 22/04/2025 v1.0 - Criação do script
    - 30/07/2025 v1.1 - Padronização do output e melhorias de legibilidade
#>

# Força o encoding UTF-8 com BOM para compatibilidade e limpa o terminal
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8BOM'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Clear-Host

# Define pasta de trabalho padrão
Set-Location "C:\Scripts"

# Carrega as variáveis do arquivo .env
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$envFile = Join-Path $scriptDir ".env"

if (-not (Test-Path $envFile)) {
  Write-Error "Arquivo .env não encontrado em $scriptDir"
  exit
}

Get-Content $envFile | ForEach-Object {
  if ($_ -match "^\s*([^#].*?)\s*=\s*(.*)\s*$") {
    [System.Environment]::SetEnvironmentVariable($matches[1], $matches[2])
  }
}

# Obtém a lista de administradores
$admins = $env:ADMINS -split "," | ForEach-Object { $_.Trim() }

if (-not $admins -or $admins.Count -eq 0) {
  Write-Warning "❌ Nenhum administrador encontrado na variável ADMINS. Verifique o arquivo .env."
  exit
}

Write-Host "Administradores configurados:"
$admins | ForEach-Object { Write-Host " - $_" }

# Importa as turmas do CSV
$csvPath = "C:\Users\dnunes\Downloads\classroom_manager.csv"

if (-not (Test-Path $csvPath)) {
  Write-Error "Arquivo CSV não encontrado: $csvPath"
  exit
}

$turmas = Import-Csv $csvPath

foreach ($turma in $turmas) {

  $id = $turma.id
  $nome = $turma.name

  Write-Host "`n============================================================"
  Write-Host "Processando turma: $nome"
  Write-Host "ID do curso: $id"
  Write-Host "------------------------------------------------------------"

  foreach ($admin in $admins) {

    Write-Host "Adicionando admin como co-professor: $admin..."

    $result = gam course $id add teacher $admin 2>&1

    if ($result -match 'Duplicate|409') {
      Write-Host "✔ Já é co-professor — nenhuma ação necessária."
    }
    elseif ($result -match 'ERROR|Failed') {
      Write-Error "❌ Erro ao adicionar ${admin}:`n$result"
    }
    else {
      Write-Host "✅ Co-professor adicionado com sucesso."
    }

    Start-Sleep -Seconds 1
  }
}

Write-Host "`n============================================================"
Write-Host "Script finalizado com sucesso."
Write-Host "============================================================"
