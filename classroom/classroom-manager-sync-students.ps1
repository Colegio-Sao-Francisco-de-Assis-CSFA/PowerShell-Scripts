<#
.SINOPSE
    Adicionar sinopse aqui

.DESCRIÇÃO
    Adicionar descrição detalhada aqui

.EXEMPLO
    .\ClassroomManager_syncStudents.ps1

.NOTAS
    Autor: Diogo
    Última atualização: 03/04/2025
#>

# Sincronizar as turmas do Google Classroom com os grupos de alunos
$turmas = Import-Csv "D:\Downloads\classroom_manager.csv"

foreach ($turma in $turmas) {

    $id = $turma.id
    $studentGroup = $turma.studentgroup

    gam course $id sync students group $studentGroup

}

Write-Warning "Script finalizado."