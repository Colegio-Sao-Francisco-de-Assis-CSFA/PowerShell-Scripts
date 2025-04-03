<#
.SINOPSE
    Adicionar sinopse aqui

.DESCRIÇÃO
    Adicionar descrição detalhada aqui

.EXEMPLO
    .\getNetIPConfig.ps1

.NOTAS
    Autor: Diogo
    Última atualização: 03/04/2025
#>

﻿#Get-NetIPConfiguration -CimSession PHELLIPE | Select-object InterfaceDescription -ExpandProperty AllIPAddresses | Export-CSV .\IPConfig.csv -NoTypeInformation
Get-NetIPInterface -CimSession IRENE
Get-NetIPConfiguration -CimSession IRENE