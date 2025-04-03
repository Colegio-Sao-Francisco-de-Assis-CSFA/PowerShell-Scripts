<#
.SINOPSE
    Adicionar sinopse aqui

.DESCRIÇÃO
    Adicionar descrição detalhada aqui

.EXEMPLO
    .\deleteFiles.ps1

.NOTAS
    Autor: Diogo
    Última atualização: 03/04/2025
#>

﻿# Solicita a pasta raiz
$rootFolder = Read-Host -Prompt "Digite o caminho da pasta onde deseja processar os arquivos"

# Verifica se a pasta existe
if (-Not (Test-Path -Path $rootFolder)) {
    Write-Host "A pasta especificada não existe. Tente novamente." -ForegroundColor Red
    exit
}

# Remover vídeos que não possuem "processed" no nome
Get-ChildItem -Path $rootFolder -Recurse -File -Filter "*.mp4" | ForEach-Object {
    if ($_.Name -notmatch "processed") {
        Remove-Item -Path $_.FullName -Force
        Write-Host "Arquivo de vídeo excluído: $($_.FullName)" -ForegroundColor Yellow
    }
}