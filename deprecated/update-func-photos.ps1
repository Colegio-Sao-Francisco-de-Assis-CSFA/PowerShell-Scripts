﻿<#
.SINOPSE
    Script descontinuado.

.DESCRIÇÃO
    Este script foi descontinuado. Substituído por `user/update-user-photos.ps1`.

.NOTAS
    Autor: Diogo
    Status: Deprecated
    Última atualização: 01/04/2025
#>

<# 
    Script: Atualização de fotos dos funcionários no Google Workspace
    Autor: Diogo
    Descrição: 
        Este script PowerShell atualiza as fotos dos usuários (funcionários) no Google Workspace 
        com base em um arquivo CSV contendo os e-mails e nomes dos funcionários, e em uma pasta com 
        as fotos nomeadas conforme o e-mail do aluno.

    Requisitos:
        - O GAM (Google Apps Manager) deve estar instalado e configurado.
        - O usuário executando o script deve ter permissões para alterar fotos de usuários no domínio.
        - A pasta com as fotos deve conter os arquivos no formato: email@dominio.com.jpg
        - O arquivo CSV deve conter pelo menos as colunas: "email" e "NOME" (com esses títulos).

    Instruções:
        1. Atualize o caminho para o arquivo CSV e a pasta com as fotos conforme necessário.
        2. Execute o script com permissões adequadas no PowerShell.

    Observação:
        Fotos ausentes serão registradas como aviso (warning) no terminal.
#>

$funcs = Import-Csv "D:\Downloads\func.csv"
$gsuitepics = "D:\Downloads\Fotos func gsuite"
$ext = "jpg"

foreach ($func in $funcs) {

    $email = $func.primaryEmail

    if (Test-Path -Path "$gsuitepics\$email.$ext" -PathType Leaf) {

        gam user $email update photo $gsuitepics\$email.$ext

        Write-Host "Foto do Google Workspace do usuário $email alterada."

    }
    else {

        Write-Warning "Arquivo $gsuitepics\$email.$ext não existe."

    }
}

Write-Warning "Script finalizado."