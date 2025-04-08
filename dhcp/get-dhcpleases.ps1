<#
.SINOPSE
    Adicionar sinopse aqui

.DESCRIÇÃO
    Adicionar descrição detalhada aqui

.EXEMPLO
    .\getDHCPLeases.ps1

.NOTAS
    Autor: Diogo
    Última atualização: 03/04/2025
#>

﻿$hora = Get-Date
Get-DhcpServerv4Lease -ComputerName "ametista.csfa.com.br" `
-ScopeId 172.16.0.0 -AllLeases | Export-Csv -Path "D:\Downloads\activeDHCPLeases.csv" -NoTypeInformation -Encoding UTF8
Write-Warning "Arquivo salvo - $hora"