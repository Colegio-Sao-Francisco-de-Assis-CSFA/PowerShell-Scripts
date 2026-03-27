# Força o encoding UTF-8 com BOM para compatibilidade e limpa o terminal
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8BOM'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Clear-Host

<#
.SINOPSE
  Gera CSV de usuários do AD e processa fotos de funcionários automaticamente.

.DESCRIÇÃO
  Este script realiza duas etapas principais:

  1. Consulta o Active Directory e gera um CSV com:
      - DisplayName
      - EmailAddress

  2. Processa fotos de funcionários:
      - Copia e renomeia arquivos com base no AD
      - Cria pastas automaticamente
      - Move arquivos processados para "originais"
      - Gera log detalhado (modo append)

  Requisitos:
    - Módulo ActiveDirectory instalado (RSAT)
    - Permissão para consultar o AD
    - Fotos nomeadas exatamente como DisplayName

.EXEMPLO
  .\processarFotos_Funcionarios_AD.ps1

.NOTAS
  Autor: Diogo
  Criado em: 26/03/2026
  Atualizado em: 26/03/2026

  Changelog:
    - 26/03/2026 v1.0 - Script inicial com integração AD
    - 26/03/2026 v1.1 - Implementação de log em modo append estruturado
#>

# =============================
# CONFIGURAÇÕES
# =============================

$caminhoCSV = "C:\Users\dnunes\Downloads\usuarios_ad.csv"
$logPath = "C:\Users\dnunes\Downloads\log_fotos_func.txt"

# =============================
# INÍCIO DO LOG (APPEND)
# =============================

# Cria o arquivo se não existir
if (-not (Test-Path $logPath)) {
  "Log de processamento de fotos" | Out-File -FilePath $logPath
  "" | Out-File -FilePath $logPath -Append
}

# Início da execução
"==============================" | Out-File -FilePath $logPath -Append
"Início: $(Get-Date)" | Out-File -FilePath $logPath -Append
"" | Out-File -FilePath $logPath -Append

# =============================
# ETAPA 1 - EXPORTAR AD
# =============================

Write-Host "Consultando Active Directory..." -ForegroundColor Cyan

try {
  $usuariosAD = Get-ADUser -Filter * -Properties DisplayName, mail | Where-Object {
    $_.DisplayName -and $_.mail
  } | Select-Object @{
    Name       = "DisplayName"
    Expression = { $_.DisplayName }
  }, @{
    Name       = "EmailAddress"
    Expression = { $_.mail }
  }

  $usuariosAD | Export-Csv -Path $caminhoCSV -NoTypeInformation

  Write-Host "[OK] CSV gerado em: $caminhoCSV" -ForegroundColor Green
  "[OK] CSV gerado em: $caminhoCSV" | Out-File -FilePath $logPath -Append
}
catch {
  $erro = "[ERRO] Falha ao consultar o Active Directory"
  Write-Host $erro -ForegroundColor Red
  $erro | Out-File -FilePath $logPath -Append
  exit
}

# =============================
# INPUT USUÁRIO
# =============================

$origem = Read-Host "Informe o caminho da pasta onde estão as fotos"
$extensao = Read-Host "Informe a extensão dos arquivos (ex: .jpg)"

# =============================
# PREPARAÇÃO
# =============================

$caminhoOriginais = Join-Path $origem "originais"
if (-not (Test-Path $caminhoOriginais)) {
  New-Item -ItemType Directory -Path $caminhoOriginais | Out-Null
}

# Importar CSV
$funcionarios = Import-Csv -Path $caminhoCSV -Delimiter ","

# Criar índice
$indiceFuncionarios = @{}
foreach ($funcionario in $funcionarios) {
  $indiceFuncionarios[$funcionario.DisplayName] = $funcionario
}

# Pastas destino
$pastasDestino = @("AD", "gsuite", "coordenacao", "classapp")

foreach ($pasta in $pastasDestino) {
  $caminhoPasta = Join-Path $origem $pasta
  if (-not (Test-Path $caminhoPasta)) {
    New-Item -ItemType Directory -Path $caminhoPasta | Out-Null
  }
}

# =============================
# PROCESSAMENTO
# =============================

Get-ChildItem -Path $origem -Filter "*$extensao" -File | ForEach-Object {

  $arquivo = $_
  $nomeArquivo = [System.IO.Path]::GetFileNameWithoutExtension($arquivo.Name)

  if ($indiceFuncionarios.ContainsKey($nomeArquivo)) {

    $funcionario = $indiceFuncionarios[$nomeArquivo]

    $destinos = @{
      "AD"          = "$($funcionario.EmailAddress)$extensao"
      "gsuite"      = "$($funcionario.EmailAddress)$extensao"
      "coordenacao" = "$($funcionario.DisplayName)$extensao"
      "classapp"    = "$($funcionario.DisplayName)$extensao"
    }

    foreach ($pasta in $destinos.Keys) {
      $destinoFinal = Join-Path (Join-Path $origem $pasta) $destinos[$pasta]
      Copy-Item -Path $arquivo.FullName -Destination $destinoFinal -Force
    }

    Move-Item -Path $arquivo.FullName -Destination $caminhoOriginais -Force

    $msg = "[OK] $($arquivo.Name) processado para $($funcionario.DisplayName)"
    Write-Host $msg -ForegroundColor Green
    $msg | Out-File -FilePath $logPath -Append
  }
  else {
    $msg = "[ERRO] $($arquivo.Name) - nome '$nomeArquivo' não encontrado no AD"
    Write-Host $msg -ForegroundColor Red
    $msg | Out-File -FilePath $logPath -Append
  }

}

# =============================
# FINAL DO LOG
# =============================

"" | Out-File -FilePath $logPath -Append
"Fim: $(Get-Date)" | Out-File -FilePath $logPath -Append
"==============================" | Out-File -FilePath $logPath -Append
"" | Out-File -FilePath $logPath -Append

Write-Host "`nProcessamento concluído! Log em: $logPath" -ForegroundColor Cyan
