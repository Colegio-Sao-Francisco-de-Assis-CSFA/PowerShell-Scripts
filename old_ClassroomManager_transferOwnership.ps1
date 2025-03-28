# Criar as turmas do Google Classroom com os parâmetros corretos
$turmas = Import-Csv "D:\Downloads\classroom_manager.csv"

foreach ($turma in $turmas) {

$nome = $turma.name
$alias = $turma.Aliases
$section = $turma.section
$room = $turma.room
$teacher = $turma.ownerEmail
$id = $turma.id

gam course $id add teacher $teacher
gam update course $id owner $teacher
Write-Host "Curso $nome atualizado para o professor $teacher"

}

Write-Warning "Script finalizado."