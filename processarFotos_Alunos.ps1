<#
  Script: processarFotos_Alunos.ps1
  Descrição:
    Este script copia arquivos de fotos de alunos para diferentes pastas (GDS, AD, gsuite, coordenacao, classapp),
    renomeando cada cópia com base nas informações do CSV (número, nome, email etc.).

  Funcionalidades:
    - Solicita a pasta de origem dos arquivos
    - Solicita o caminho do CSV (com separador vírgula)
    - Solicita a extensão dos arquivos
    - Copia as fotos para múltiplas pastas, renomeando conforme os dados
    - Gera um log de sucesso/erro
    - Move as fotos originais para uma subpasta "originais"

  Observações:
    - Os arquivos devem ter como nome o código do aluno (campo NUMERO no CSV)
    - O CSV deve estar no formato UTF-8 com separador vírgula
#>

# Força o terminal a usar UTF-8 (pode ajudar em PowerShell + Windows Terminal + VS Code)
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Limpa o terminal
Clear-Host

# Solicita ao usuário a pasta onde estão os arquivos
$origem = Read-Host "Informe o caminho da pasta onde estão os arquivos (sem aspas)"

# Solicita o caminho do arquivo CSV
$caminhoCSV = Read-Host "Informe o caminho completo do arquivo CSV (sem aspas)"

# Solicita a extensão dos arquivos que devem ser processados
$extensao = Read-Host "Informe a extensão dos arquivos (ex: .jpg, .png)"

# Caminho do log
$logPath = "D:\Downloads\log_fotos.txt"

# Inicia o log (UTF-8 sem BOM, com Set-Content)
"Log de processamento - $(Get-Date)" | Set-Content -Path $logPath -Encoding utf8
"" | Add-Content -Path $logPath

# Lê o conteúdo do CSV usando vírgula como separador
$alunos = Import-Csv -Path $caminhoCSV -Delimiter ","

# Cria pastas de destino, se ainda não existirem
$pastasDestino = @("GDS", "AD", "gsuite", "coordenacao", "classapp", "SIGA")

foreach ($pasta in $pastasDestino) {
  $caminhoPasta = Join-Path $origem $pasta
  if (-not (Test-Path $caminhoPasta)) {
    New-Item -ItemType Directory -Path $caminhoPasta | Out-Null
  }
}

# Processa cada arquivo conforme os dados do CSV
foreach ($arquivo in Get-ChildItem -Path $origem -Filter "*$extensao" -File) {
  $nomeArquivo = [System.IO.Path]::GetFileNameWithoutExtension($arquivo.Name)
  $aluno = $alunos | Where-Object { $_.NUMERO -eq $nomeArquivo }

  if ($aluno) {
    # Copia para cada pasta com o nome apropriado
    Copy-Item $arquivo.FullName -Destination (Join-Path $origem\GDS "$($aluno.NUMERO)$extensao")
    Copy-Item $arquivo.FullName -Destination (Join-Path $origem\AD "$($aluno.email)$extensao")
    Copy-Item $arquivo.FullName -Destination (Join-Path $origem\gsuite "$($aluno.email)$extensao")
    Copy-Item $arquivo.FullName -Destination (Join-Path $origem\coordenacao "$($aluno.nome)$extensao")
    Copy-Item $arquivo.FullName -Destination (Join-Path $origem\classapp "$($aluno.nome)$extensao")
    Copy-Item $arquivo.FullName -Destination (Join-Path $origem\SIGA "$($aluno.NUMERO)$extensao")

    # Mensagem de sucesso
    $msg = "[OK] $($arquivo.Name) processado para $($aluno.nome)"
    Write-Host $msg -ForegroundColor Green
    $msg | Add-Content -Path $logPath
  }
  else {
    # Mensagem de erro
    $msg = "[ERRO] $($arquivo.Name) - código $nomeArquivo não encontrado no CSV"
    Write-Host $msg -ForegroundColor Red
    $msg | Add-Content -Path $logPath
  }
}

# Move os arquivos originais para a subpasta "originais"
$caminhoOriginais = Join-Path $origem "originais"
if (-not (Test-Path $caminhoOriginais)) {
  New-Item -ItemType Directory -Path $caminhoOriginais | Out-Null
}

Get-ChildItem -Path $origem -Filter "*$extensao" -File | ForEach-Object {
  Move-Item $_.FullName -Destination $caminhoOriginais
}

# Finaliza e abre o log
Write-Host "`nProcessamento concluído! O log foi salvo em $logPath" -ForegroundColor Cyan
Start-Process notepad.exe $logPath
