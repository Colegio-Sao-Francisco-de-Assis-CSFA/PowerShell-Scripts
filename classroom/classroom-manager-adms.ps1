<#
.SINOPSE
    Adicionar sinopse aqui

.DESCRIÇÃO
    Adicionar descrição detalhada aqui

.EXEMPLO
    .\ClassroomManager_ADMs.ps1

.NOTAS
    Autor: Diogo
    Última atualização: 03/04/2025
#>

﻿# Criar as turmas do Google Classroom com os parâmetros corretos
$turmas = Import-Csv "D:\Downloads\turmas-extras.csv"

foreach ($turma in $turmas) {

$nome = $turma.name
$alias = $turma.Aliases
$section = $turma.section
$room = $turma.room
$id = $turma.id
$teacher = $turma.ownerEmail

gam course $id add teacher irene@colsaofrancisco.com.br
gam course $id add teacher phellipe@colsaofrancisco.com.br
gam course $id add teacher andre.santos@colsaofrancisco.com.br
gam course $id add teacher cloves.neto@colsaofrancisco.com.br

}

Write-Warning "Script finalizado."