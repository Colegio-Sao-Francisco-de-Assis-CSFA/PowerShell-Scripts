$dir = "D:\Downloads\Fotos alunos nome e cod"
$ext = "jpg"

$files = Import-Csv "D:\Downloads\alunos.csv"

foreach ($file in $files) {

$cod = $file.NUMERO
$nome = $file.NOME
$email = $file.email

if (Test-Path $dir\$nome.$ext) {

Rename-Item -Path $dir\$nome.$ext -NewName "$dir\$nome - $cod.$ext"

Write-Host "Arquivo $nome.$ext renomeado com sucesso para $nome - $cod.$ext"

}

else {

Write-Warning "O arquivo $nome.$ext não existe"

}

}