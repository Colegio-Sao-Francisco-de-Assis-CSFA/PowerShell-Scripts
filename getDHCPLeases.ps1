$hora = Get-Date
Get-DhcpServerv4Lease -ComputerName "ametista.csfa.com.br" `
-ScopeId 172.16.0.0 -AllLeases | Export-Csv -Path .\activeDHCPLeases.csv -NoTypeInformation -Encoding UTF8
Write-Warning "Arquivo salvo - $hora"