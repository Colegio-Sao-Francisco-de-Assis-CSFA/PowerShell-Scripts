<#
.SINOPSE
    Adicionar sinopse aqui

.DESCRIÇÃO
    Adicionar descrição detalhada aqui

.EXEMPLO
    .\uploadFilesToDrive.ps1

.NOTAS
    Autor: Diogo
    Última atualização: 03/04/2025
#>

﻿# Set the folder path
$folderPath = Read-Host "Em qual pasta local estão os arquivos?"
$username = Read-Host "Qual o e-mail do usuário destino?"
$parentID = Read-Host "Qual o ID da pasta que os arquivos devem ser colocados?"

# Check if the folder exists
if (Test-Path $folderPath -PathType Container) {

# Get all files in the folder
$files = Get-ChildItem -Path $folderPath

# Loop through each file and run the command
foreach ($file in $files) {
    $filePath = $file.FullName
    gam user $username add drivefile localfile $filePath parentid $parentID 2>&1
    #Write-Host "Arquivo $file salvo com sucesso." 
    
}
} else {

Write-Warning "A pasta local não existe."

}