$Leases = Import-csv "D:\Downloads\dhcp.csv"

foreach ($Lease in $Leases)
{

$ip = $Lease.IPAddress
$Nome = $Lease.HostName
$mac = $Lease.ClientId
$desc = $Lease.Description
$scope = $Lease.ScopeId

Add-DhcpServerv4Reservation -ComputerName "ametista.csfa.com.br" -ScopeId $scope -IPAddress $ip -Name "$Nome" -ClientId "$mac" -Description "$desc"
Write-Warning "Reserva $Nome | $desc | $ip | $mac adicionada ao DHCP."
}