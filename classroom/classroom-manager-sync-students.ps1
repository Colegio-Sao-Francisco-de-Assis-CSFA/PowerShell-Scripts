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

# Força o encoding UTF-8 com BOM para compatibilidade e limpa o terminal
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8BOM'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Clear-Host

# Sincronizar as turmas do Google Classroom com os grupos de alunos
$turmas = Import-Csv "D:\Downloads\classroom_manager.csv"

foreach ($turma in $turmas) {

  $id = $turma.id
  $studentGroup = $turma.studentgroup

  gam course $id sync students group $studentGroup

}

Write-Warning "Script finalizado."