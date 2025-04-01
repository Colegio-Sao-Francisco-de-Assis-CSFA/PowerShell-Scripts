<#
  Script: processarFotos_Funcionarios.ps1
  Descrição:
    Este script copia fotos de funcionários para as pastas ad, gsuite, coordenacao e classapp,
    renomeando os arquivos com base nas informações do CSV. A busca no CSV ignora acentos.

  Funcionalidades:
    - Solicita a pasta com as fotos
    - Solicita o caminho do CSV (separador vírgula)
    - Solicita a extensão dos arquivos
    - Faz correspondência do nome do arquivo com o campo "nome" do CSV, ignorando acentos
    - Copia os arquivos com nomes diferentes para múltiplas pastas
    - Gera log detalhado e move os arquivos originais para a pasta "originais"

  Observações:
    - Os nomes dos arquivos devem estar no mesmo padrão do campo "nome" do CSV, sem acento
    - Os arquivos devem estar em UTF-8
#>

# Força saída em UTF-8 (log + terminal)
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Limpa o terminal
Clear-Host

# Função para remover acentos (normalização Unicode)
function RemoverAcentos($texto) {
  $normalized = $texto.Normalize([Text.NormalizationForm]::FormD)
  return -join ($normalized.ToCharArray() | Where-Object { [Globalization.CharUnicodeInfo]::GetUnicodeCategory($_) -ne 'NonSpacingMark' })
}

# Solicita informações ao usuário
$origem = Read-Host "Informe o caminho da pasta onde estão os arquivos (sem aspas)"
$caminhoCSV = Read-Host "Informe o caminho completo do arquivo CSV (sem aspas)"
$extensao = Read-Host "Informe a extensão dos arquivos (ex: .jpg, .png)"

# Caminho do log
$logPath = "D:\Downloads\log_fotos_funcionarios.txt"
"Log de processamento - $(Get-Date)" | Set-Content -Path $logPath -Encoding utf8
"" | Add-Content -Path $logPath

# Lê o conteúdo do CSV (vírgula como separador)
$funcionarios = Import-Csv -Path $caminhoCSV -Delimiter ","

# Cria pastas de destino
$pastasDestino = @("coordenacao", "ad", "gsuite", "classapp")
foreach ($pasta in $pastasDestino) {
  $caminhoPasta = Join-Path $origem $pasta
  if (-not (Test-Path $caminhoPasta)) {
    New-Item -ItemType Directory -Path $caminhoPasta | Out-Null
  }
}

# Processa os arquivos
foreach ($arquivo in Get-ChildItem -Path $origem -Filter "*$extensao" -File) {
  $nomeArquivo = RemoverAcentos ([System.IO.Path]::GetFileNameWithoutExtension($arquivo.Name)).ToLower()

  # Tenta encontrar o funcionário pelo nome sem acento
  $funcionario = $funcionarios | Where-Object {
        (RemoverAcentos($_.nome).ToLower() -EQ $nomeArquivo)
  }

  if ($funcionario) {
    $novoNome = "$($funcionario.nome)$extensao"

    # Copia os arquivos com os nomes apropriados
    Copy-Item $arquivo.FullName -Destination (Join-Path $origem\coordenacao $novoNome)
    Copy-Item $arquivo.FullName -Destination (Join-Path $origem\ad "$($funcionario.email)$extensao")
    Copy-Item $arquivo.FullName -Destination (Join-Path $origem\gsuite "$($funcionario.email)$extensao")
    Copy-Item $arquivo.FullName -Destination (Join-Path $origem\classapp $novoNome)

    $msg = "[OK] $($arquivo.Name) processado para $($funcionario.nome)"
    Write-Host $msg -ForegroundColor Green
    $msg | Add-Content -Path $logPath
  }
  else {
    $msg = "[ERRO] $($arquivo.Name) - nome correspondente não encontrado no CSV"
    Write-Host $msg -ForegroundColor Red
    $msg | Add-Content -Path $logPath
  }
}

# Move arquivos originais para a subpasta 'originais'
$caminhoOriginais = Join-Path $origem "originais"
if (-not (Test-Path $caminhoOriginais)) {
  New-Item -ItemType Directory -Path $caminhoOriginais | Out-Null
}
Get-ChildItem -Path $origem -Filter "*$extensao" -File | ForEach-Object {
  Move-Item $_.FullName -Destination $caminhoOriginais
}

# Finalização
Write-Host "`nProcessamento concluído! O log foi salvo em $logPath" -ForegroundColor Cyan
Start-Process notepad.exe $logPath
