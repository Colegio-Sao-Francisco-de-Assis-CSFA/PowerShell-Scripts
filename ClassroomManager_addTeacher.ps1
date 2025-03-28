# Criar as turmas do Google Classroom com os parâmetros corretos
$turmas = Import-Csv "D:\Downloads\classroom-manager.csv"

foreach ($turma in $turmas) {

$nome = $turma.name
$alias = $turma.Aliases
$section = $turma.section
$room = $turma.room
$id = $turma.id
$teacher = $turma.ownerEmail

gam course $id add teacher $teacher
gam update course $id teacher $teacher

Write-Warning "Professor $teacher adicionado ao curso $nome."

}

Write-Warning "Script finalizado."