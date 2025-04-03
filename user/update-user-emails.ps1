<#
.SINOPSE
    Adicionar sinopse aqui

.DESCRIÇÃO
    Adicionar descrição detalhada aqui

.EXEMPLO
    .\updateUserEmails.ps1

.NOTAS
    Autor: Diogo
    Última atualização: 03/04/2025
#>

﻿$users = Import-Csv "D:\Downloads\updateemails.csv"

foreach ($user in $users) {

Set-ADUser -Identity $user.SamAccountName -EmailAddress $user.EmailAddress

Write-Host "Usuário $user.SamAccountName atualizado com o e-mail $user.EmailAddress"

}