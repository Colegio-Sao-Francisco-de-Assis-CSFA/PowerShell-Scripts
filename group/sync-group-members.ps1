<#
.SINOPSE
    Adicionar sinopse aqui

.DESCRIÇÃO
    Adicionar descrição detalhada aqui

.EXEMPLO
    .\syncGroupMembers.ps1

.NOTAS
    Autor: Diogo
    Última atualização: 03/04/2025
#>

$grupos = Import-Csv "D:\Downloads\sync.csv"

foreach ($grupo in $grupos) {

  $novo = $grupo.grupo
  $sync = $grupo.sync

  gam update group $novo sync member group $sync

}