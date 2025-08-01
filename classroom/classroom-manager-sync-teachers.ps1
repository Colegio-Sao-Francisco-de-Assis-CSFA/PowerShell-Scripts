<#
.SINOPSE
    Adicionar sinopse aqui

.DESCRIÇÃO
    Adicionar descrição detalhada aqui

.EXEMPLO
    .\ClassroomManager_syncTeachers.ps1

.NOTAS
    Autor: Diogo
    Última atualização: 03/04/2025
#>

# Criar as turmas do Google Classroom com os parâmetros corretos
$turmas = Import-Csv "D:\Downloads\classroom_manager.csv"

foreach ($turma in $turmas) {

  $id = $turma.id
  $teacherGroup = $turma.teachergroup

  gam course $id sync teachers group $teacherGroup

}

Write-Warning "Script finalizado."