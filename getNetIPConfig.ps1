#Get-NetIPConfiguration -CimSession PHELLIPE | Select-object InterfaceDescription -ExpandProperty AllIPAddresses | Export-CSV .\IPConfig.csv -NoTypeInformation
Get-NetIPInterface -CimSession IRENE
Get-NetIPConfiguration -CimSession IRENE