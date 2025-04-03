<#
.SINOPSE
    Adicionar sinopse aqui

.DESCRIÇÃO
    Adicionar descrição detalhada aqui

.EXEMPLO
    .\uploadAudiosToDrive.ps1

.NOTAS
    Autor: Diogo
    Última atualização: 03/04/2025
#>

﻿# Definir caminhos e nomes de pastas
$csvFilePath = "D:\Downloads\alunos3em.csv" # Caminho para o arquivo CSV com informações dos usuários
$mp3FolderPath = "D:\Downloads\audios Eduardo Green"   # Pasta contendo os arquivos MP3
$destinationFolderName = "Aula de Projeto de Vida" # Nome da pasta no Google Drive

# Ler o arquivo CSV
$userList = Import-Csv -Path $csvFilePath

# Loop para cada usuário no arquivo CSV
foreach ($user in $userList) {
    $email = $user.Email
    $name = $user.Name
    $mp3FileName = "$name.mp3"
    $mp3FilePath = Join-Path -Path $mp3FolderPath -ChildPath $mp3FileName
    
    # Verificar se o arquivo MP3 existe para o usuário
    if (Test-Path -Path $mp3FilePath) {
        # Criar uma pasta no Google Drive do usuário
        & gam user $email add drivefile drivefilename "$destinationFolderName" mimetype gfolder

        # Fazer upload do arquivo MP3 para a pasta no Google Drive
        & gam user $email add drivefile drivefilename "$name" localfile $mp3FilePath parentname "$destinationFolderName"

        Write-Output "Upload do arquivo $mp3FileName para a pasta '$destinationFolderName' no Google Drive de $email concluído com sucesso."
    } else {
        Write-Output "Arquivo MP3 para $name ($mp3FileName) não encontrado em $mp3FolderPath."
    }
}
