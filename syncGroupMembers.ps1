$grupos = Import-Csv "D:\Downloads\sync.csv"

foreach ($grupo in $grupos) {

$novo = $grupo.grupo
$sync = $grupo.sync

gam update group $novo sync member group $sync

}