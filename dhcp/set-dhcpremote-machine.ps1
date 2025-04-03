<#
.SINOPSE
    Adicionar sinopse aqui

.DESCRIÇÃO
    Adicionar descrição detalhada aqui

.EXEMPLO
    .\setDHCPRemoteMachine.ps1

.NOTAS
    Autor: Diogo
    Última atualização: 03/04/2025
#>

﻿$computers = Import-csv "D:\Downloads\alunosnovos2807.csv"

#Get-Help Update-IPv4Address -examples
#Update-IPv4Address -ComputerName PHELLIPE -InterfaceAlias Ethernet -PrefixLength 16 -DisableDhcp No -DisableDnsRegistration No -Verbose


Set-NetIPInterface -InterfaceIndex 15 -Dhcp Enabled -CimSession PHELLIPE -Verbose