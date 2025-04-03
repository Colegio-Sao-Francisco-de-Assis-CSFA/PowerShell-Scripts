<#
.SINOPSE
    Adicionar sinopse aqui

.DESCRIÇÃO
    Adicionar descrição detalhada aqui

.EXEMPLO
    .\updateDisplayName.ps1

.NOTAS
    Autor: Diogo
    Última atualização: 03/04/2025
#>

﻿$alunos = Import-Csv "D:\Downloads\todosalunos.csv"

foreach ($aluno in $alunos) {

$firstname = $aluno.firstname
$surname = $aluno.surname

# Replace "username" with the actual username of the user you want to update
$username = $aluno.adusername

# Replace "New Display Name" with the new display name you want to set for the user
$newDisplayName = "$firstname $surname"

# Connect to Active Directory
Import-Module ActiveDirectory

# Get the user object from Active Directory
$user = Get-ADUser -Identity $username

# Update the display name of the user object
Set-ADUser -Identity $user -DisplayName $newDisplayName

Write-Warning "DisplayName do usuário $username alterado para $newDisplayName."
}