<#
.SINOPSE
    Adicionar sinopse aqui

.DESCRIÇÃO
    Adicionar descrição detalhada aqui

.EXEMPLO
    .\updateDHCP.ps1

.NOTAS
    Autor: Diogo
    Última atualização: 03/04/2025
#>

﻿# Define the DHCP server and scope you want to modify
$DHCPServer = "DHCP-Server-Name"
$DHCPScope = "192.168.1.0"

# Define the IP address and MAC address of the DHCP client you want to modify
$OldIP = "192.168.1.100"
$OldMAC = "00-11-22-33-44-55"

# Define the new IP address, MAC address, and description you want to assign to the client
$NewIP = "192.168.1.200"
$NewMAC = "00-11-22-33-44-66"
$NewDescription = "New Client Description"

# Retrieve the DHCP lease information for the client you want to modify
$Lease = Get-DhcpServerv4Lease -ComputerName $DHCPServer -ScopeId $DHCPScope -IPAddress $OldIP -ClientId $OldMAC

# Modify the lease information with the new IP address, MAC address, and description
$Lease.IPAddress = $NewIP
$Lease.ClientId = $NewMAC
$Lease.Description = $NewDescription

# Set the updated lease information on the DHCP server
Set-DhcpServerv4Lease -ComputerName $DHCPServer -ScopeId $DHCPScope -Lease $Lease
