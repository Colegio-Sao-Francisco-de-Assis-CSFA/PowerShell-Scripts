<#
.SINOPSE
    Adicionar sinopse aqui

.DESCRIÇÃO
    Adicionar descrição detalhada aqui

.EXEMPLO
    .\resizeAndConvertFiles.ps1

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

# Função para processar vídeos MP4
function Process-MP4Files {
    param ($filePath)
    $outputFilePath = [System.IO.Path]::ChangeExtension($filePath, ".processed.mp4")

    # Comando ffmpeg para reduzir bitrate para 3000k
    ffmpeg -i "$filePath" -b:v 3000k -c:a copy "$outputFilePath"
    if ($?) {
        Write-Host "Arquivo de vídeo processado: $outputFilePath" -ForegroundColor Green
    } else {
        Write-Host "Erro ao processar vídeo: $filePath" -ForegroundColor Red
    }
}

# Função para converter imagens HEIC para JPG
function Convert-HEICtoJPG {
    param ($filePath)
    $outputFilePath = [System.IO.Path]::ChangeExtension($filePath, ".jpg")

    # Comando ffmpeg para converter HEIC para JPG
    ffmpeg -i "$filePath" "$outputFilePath"
    if ($?) {
        Write-Host "Imagem convertida: $outputFilePath" -ForegroundColor Green
    } else {
        Write-Host "Erro ao converter imagem: $filePath" -ForegroundColor Red
    }
}

# Procura e processa arquivos em subpastas
Get-ChildItem -Path $rootFolder -Recurse -File | ForEach-Object {
    if ($_.Extension -eq ".mp4") {
        Process-MP4Files -filePath $_.FullName
    }
    elseif ($_.Extension -eq ".HEIC") {
        Convert-HEICtoJPG -filePath $_.FullName
    }
}

# Remover vídeos que não possuem "processed" no nome
Get-ChildItem -Path $rootFolder -Recurse -File -Filter "*.mp4" | ForEach-Object {
    if ($_.Name -notmatch "processed") {
        Remove-Item -Path $_.FullName -Force
        Write-Host "Arquivo de vídeo excluído: $($_.FullName)" -ForegroundColor Yellow
    }
}

Write-Host "Processamento concluído." -ForegroundColor Cyan
