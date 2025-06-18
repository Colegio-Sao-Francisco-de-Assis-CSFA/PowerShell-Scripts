<#
  .SINOPSE
    Envia todos os arquivos de uma pasta local (incluindo subpastas) para uma pasta específica no Google Drive usando GAM.

  .DESCRIÇÃO
    Este script itera de forma recursiva sobre todos os arquivos de uma pasta e suas subpastas e faz upload de cada um para uma 
    pasta do Google Drive utilizando o comando `gam user ... add drivefile`. Ideal para automatizar o envio de lotes grandes 
    de arquivos, mantendo a estrutura de pastas local se necessário.

  .EXEMPLO
    .\upload-arquivos-drive.ps1

  .NOTAS
    Autor: Diogo
    Última atualização: 17/06/2025
#>

# Força o encoding UTF-8 com BOM para compatibilidade e limpa o terminal
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8BOM'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Clear-Host

# Caminho padrão da pasta de trabalho
$diretorioScripts = "D:\Scripts"
Set-Location -Path $diretorioScripts

# Solicita os parâmetros ao usuário
$EmailUsuario = Read-Host "Digite o e-mail do usuário do Google Workspace (ex: usuario@dominio.com)"
$IdPastaDrive = Read-Host "Digite o ID da pasta no Google Drive"
$CaminhoLocal = Read-Host "Digite o caminho completo da pasta com os arquivos a enviar (ex: D:\Downloads\documentos)"

# Verifica se a pasta existe
if (-Not (Test-Path $CaminhoLocal)) {
  Write-Host "❌ Caminho inválido. Verifique e tente novamente." -ForegroundColor Red
  exit
}

# Itera recursivamente sobre os arquivos e faz o upload com GAM
Get-ChildItem -Path $CaminhoLocal -Recurse -File | ForEach-Object {
  $arquivo = $_.FullName
  $nome = $_.Name
  Write-Host "📤 Enviando: $nome" -ForegroundColor Cyan

  & gam.exe user $EmailUsuario add drivefile localfile "$arquivo" parentid $IdPastaDrive

  if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Enviado com sucesso: $nome" -ForegroundColor Green
  }
  else {
    Write-Host "⚠️ Erro ao enviar: $nome" -ForegroundColor Yellow
  }
}
