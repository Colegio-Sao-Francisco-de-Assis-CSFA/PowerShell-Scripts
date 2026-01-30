<#
.SINOPSE
    Adicionar sinopse aqui

.DESCRIÇÃO
    Adicionar descrição detalhada aqui

.EXEMPLO
    .\addDhcpReservation.ps1

.NOTAS
    Autor: Diogo
    Última atualização: 03/04/2025
#>

$Leases = Import-Csv "C:\Users\dnunes\Downloads\dhcp.csv"

foreach ($Lease in $Leases) {

    $ip = $Lease.IPAddress
    $Nome = $Lease.HostName
    $mac = $Lease.ClientId
    $desc = $Lease.Description
    $scope = $Lease.ScopeId

    Add-DhcpServerv4Reservation -ComputerName "ametista.csfa.com.br" -ScopeId $scope -IPAddress $ip -Name "$Nome" -ClientId "$mac" -Description "$desc"
    Write-Warning "Reserva $Nome | $desc | $ip | $mac adicionada ao DHCP."
}