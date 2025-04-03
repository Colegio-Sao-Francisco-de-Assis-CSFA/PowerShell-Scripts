<#
.SINOPSE
    Adicionar sinopse aqui

.DESCRIÇÃO
    Adicionar descrição detalhada aqui

.EXEMPLO
    .\getADUsers.ps1

.NOTAS
    Autor: Diogo
    Última atualização: 03/04/2025
#>

﻿# Conectar ao Active Directory
Import-Module ActiveDirectory

# Recuperar informações dos usuários e exportar para CSV
Get-ADUser -Filter * -Properties SamAccountName, DisplayName, EmailAddress, DistinguishedName, Enabled |
Select-Object SamAccountName, DisplayName, EmailAddress, @{Name="OU";Expression={($_.DistinguishedName -split ",")[1] -replace "OU=",""}}, Enabled |
Export-Csv -Path "D:\Scripts\AllADUsers.csv" -NoTypeInformation -Encoding UTF8

# Exibir mensagem de conclusão com timestamp
$hora = Get-Date
Write-Warning "Arquivo salvo - $hora"
