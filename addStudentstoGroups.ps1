#Adicionar alunos aos grupos a partir do arquivo CSV
$turmas = Import-Csv "D:\Downloads\todos23.csv"

foreach ($turma in $turmas) {

$group = $turma.grupo
$aluno = $turma.email
$firstname = $turma.firstname
$surname = $turma.surname
$fullname = "$firstname $surname"

gam update group $group add member user $aluno

Write-Warning "Aluno $fullname adicionado ao grupo $group."

}