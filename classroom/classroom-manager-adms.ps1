<#
  .SINOPSE
    Adiciona os administradores responsáveis em todas as turmas do Google Classroom.

  .DESCRIÇÃO
    Este script lê um arquivo CSV com as turmas extras e adiciona os administradores como co-professores
    utilizando comandos GAM. Ideal para turmas supervisionadas por coordenadores, equipe de TI, etc.

  .EXEMPLO
    .\classroom-manager-adms.ps1

  .NOTAS
    Autor: Diogo
    Última atualização: 22/04/2025
#>

# Força o encoding UTF-8 com BOM para compatibilidade e limpa o terminal
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8BOM'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Clear-Host

# Carrega as variáveis do .env
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$envFile = Join-Path $scriptDir ".env"

Get-Content $envFile | ForEach-Object {
  if ($_ -match "^\s*([^#].*?)\s*=\s*(.*)\s*$") {
    [System.Environment]::SetEnvironmentVariable($matches[1], $matches[2])
  }
}

# Obtém a lista de admins a partir da variável de ambiente
$admins = $env:ADMINS -split "," | ForEach-Object { $_.Trim() }

# Verifica se há administradores definidos
if (-not $admins -or $admins.Count -eq 0 -or ($admins -eq "")) {
  Write-Warning "❌ Nenhum administrador encontrado na variável ADMINS. Verifique o arquivo .env."
  exit
}

# Importa a lista de turmas extras a partir de um arquivo CSV
$turmas = Import-Csv "D:\Downloads\classroom_manager.csv"

# Itera sobre cada turma no CSV e adiciona os administradores
foreach ($turma in $turmas) {

  $id = $turma.id
  # Adiciona os administradores/coordenadores como professores adicionais  
  foreach ($admin in $admins) {
    gam course $id add teacher $admin
    Write-Host "$admin"
  }
}

Write-Warning "Script finalizado."
