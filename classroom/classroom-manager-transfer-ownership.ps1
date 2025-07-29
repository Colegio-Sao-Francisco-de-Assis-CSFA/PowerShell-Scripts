<#
.SINOPSE
    Adicionar sinopse aqui

.DESCRIÇÃO
    Adicionar descrição detalhada aqui

.EXEMPLO
    .\ClassroomManager_transferOwnership.ps1

.NOTAS
    Autor: Diogo
    Última atualização: 03/04/2025
#>

# Import classroom data from CSV
$turmas = Import-Csv "D:\Downloads\classroom_manager.csv"

foreach ($turma in $turmas) {

    $nome = $turma.name
    $teacher = $turma.ownerEmail
    $id = $turma.id

    # Add teacher to the course, if not already a teacher
    $addTeacherOutput = gam courses $id add teachers $teacher

    if ($addTeacherOutput -match "409: Requested entity already exists") {
        Write-Host "Professor $teacher já é professor do curso $nome."
    }
    elseif ($addTeacherOutput -match "ERROR:") {
        Write-Error "Erro ao tentar adicionar professor $teacher ao curso $nome."
    }
    else {
        Write-Warning "Professor $teacher adicionado ao curso $nome."
    }

    # Update course owner, if not already the owner
    $updateOwnerOutput = gam update course $id teacher $teacher

    if ($updateOwnerOutput -match "400: @UserAlreadyOwner") {
        Write-Host "Professor $teacher já é proprietário do curso $nome."
    }
    elseif ($updateOwnerOutput -match "ERROR:") {
        Write-Error "Erro ao tentar transferir a propriedade do curso $nome para $teacher."
    }
    else {
        Write-Warning "Curso $nome atualizado para o novo proprietário $teacher."
    }
}

Write-Warning "Script finalizado."
