# Criar as turmas do Google Classroom com os parâmetros corretos
$turmas = Import-Csv "D:\Downloads\classroom_manager.csv"

foreach ($turma in $turmas) {

$nome = $turma.name
$alias = $turma.Aliases
$section = $turma.section
$room = $turma.room
$id = $turma.id
$teacher = $turma.ownerEmail
$teacherGroup = $turma.teachergroup
$studentGroup = $turma.studentgroup

gam course $id sync teachers group $teacherGroup
#gam update course $id owner $teacher

#Write-Warning "Professor $teacher adicionado ao curso $nome."

}

Write-Warning "Script finalizado."