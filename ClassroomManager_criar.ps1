# Criar as turmas do Google Classroom com os parâmetros corretos
$turmas = Import-Csv "D:\Downloads\classroom_manager.csv"

foreach ($turma in $turmas) {

$nome = $turma.name
$alias = $turma.Aliases
$section = $turma.section
$room = $turma.room
$teacher = $turma.ownerEmail

gam create course name "$nome" alias "$alias" section "$section" room "$room" status ACTIVE teacher diogo@colsaofrancisco.com.br
Write-Host "Curso $nome com o alias $alias criado"

}

Write-Warning "Script finalizado."