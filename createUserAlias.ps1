$sempres = Import-Csv "D:\Downloads\csfaparasempre.csv"

foreach ($sempre in $sempres) {

$email = $sempre.primaryEmail
$alias1 = $sempre.alias1
$alias2 = $sempre.alias2

gam create aliases $alias1 $alias2 user $email

}