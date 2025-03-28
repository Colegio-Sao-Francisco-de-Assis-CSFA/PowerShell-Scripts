#Atualizar fotos dos alunos no Gsuite a partir do arquivo CSV

$alunos = Import-Csv "D:\Downloads\alunos.csv"
$gsuitepics = "D:\Downloads\Fotos alunos gsuite"
$ext = "jpg"

foreach ($aluno in $alunos) {

$cod = $aluno.NUMERO
$email = $aluno.email
$adusername = $aluno.adusername

if (Test-Path -Path "$gsuitepics\$cod.$ext" -PathType Leaf) {

gam user $email update photo $gsuitepics\$cod.$ext

Write-Host "Foto do Google Workspace do usuário $email alterada."

} else {

Write-Warning "Arquivo $gsuitepics\$cod.$ext não existe."
} }

Write-Warning "Script finalizado."