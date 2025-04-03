﻿<#
================================================================================
Script:      converter-utf8bom.ps1
Descrição:  Este script solicita ao usuário uma pasta base e percorre todos os
            arquivos `.ps1` dentro dela (inclusive em subpastas), realizando:
              - Backup do arquivo original com extensão `.bak`;
              - Conversão do conteúdo para codificação UTF-8 sem BOM usando
                [System.Text.Encoding]::UTF8;
              - Registro de log no arquivo D:\Downloads\conversao-utf8bom-log.txt

Uso:        Execute o script no PowerShell e informe o caminho completo da pasta.
            Ao final, um log da operação será salvo em:
            D:\Downloads\conversao-utf8bom-log.txt
================================================================================
#>

# Solicita ao usuário o caminho da pasta base
$basePath = Read-Host "Digite o caminho completo da pasta onde estão os scripts"
$logPath = "D:\Downloads\conversao-utf8bom-log.txt"
"" > $logPath  # Limpa o log

# Verifica se a pasta existe
if (-Not (Test-Path $basePath)) {
  Write-Host "❌ Caminho inválido. Verifique e tente novamente." -ForegroundColor Red
  Add-Content -Path $logPath -Value "Caminho inválido fornecido: $basePath"
  exit
}

# Processa todos os arquivos .ps1 recursivamente
Get-ChildItem -Path $basePath -Recurse -Filter *.ps1 | ForEach-Object {
  $file = $_.FullName
  $backup = "$file.bak"
  $status = "Convertido com sucesso"

  try {
    Write-Host "🔄 Backup e conversão: $file" -ForegroundColor Cyan
    Copy-Item -Path $file -Destination $backup -Force
    $conteudo = Get-Content -Path $file -Raw
    [System.IO.File]::WriteAllText($file, $conteudo, [System.Text.Encoding]::UTF8)
  }
  catch {
    $status = "Erro: $_"
    Write-Host "❌ Erro ao processar $file" -ForegroundColor Red
  }

  Add-Content -Path $logPath -Value "$file => $status"
}

Write-Host "`n✅ Conversão finalizada. Log salvo em: $logPath" -ForegroundColor Green
