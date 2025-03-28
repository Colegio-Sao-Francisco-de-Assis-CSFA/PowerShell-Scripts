# Conectar ao Active Directory
Import-Module ActiveDirectory

# Recuperar informações dos usuários e exportar para CSV
Get-ADUser -Filter * -Properties SamAccountName, DisplayName, EmailAddress, DistinguishedName, Enabled |
Select-Object SamAccountName, DisplayName, EmailAddress, @{Name="OU";Expression={($_.DistinguishedName -split ",")[1] -replace "OU=",""}}, Enabled |
Export-Csv -Path "D:\Scripts\AllADUsers.csv" -NoTypeInformation -Encoding UTF8

# Exibir mensagem de conclusão com timestamp
$hora = Get-Date
Write-Warning "Arquivo salvo - $hora"
