#Atualizar fotos dos alunos a partir do arquivo CSV

$funcs = Import-Csv "D:\Downloads\func.csv"
$gsuitepics = "D:\Downloads\Fotos func gsuite"
$ext = "jpg"

foreach ($func in $funcs) {

$email = $func.primaryEmail

if (Test-Path -Path "$gsuitepics\$email.$ext" -PathType Leaf) {

gam user $email update photo $gsuitepics\$email.$ext

Write-Host "Foto do Google Workspace do usuário $email alterada."

} else {

Write-Warning "Arquivo $gsuitepics\$email.$ext não existe."

}
}

Write-Warning "Script finalizado."