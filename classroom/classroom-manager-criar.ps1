﻿<#
  .SINOPSE
    Cria turmas no Google Classroom com os parâmetros definidos em um CSV.

  .DESCRIÇÃO
    Este script importa um arquivo CSV contendo os dados das turmas (nome, alias, seção, sala e professor)
    e cria as turmas utilizando o GAM, definindo o status como ativo.

  .EXEMPLO
    .\classroom-manager-criar.ps1

  .NOTAS
    Autor: Diogo
    Última atualização: 08/04/2025
#>

# Importa as turmas a partir de um arquivo CSV
$turmas = Import-Csv "D:\Downloads\classroom_manager.csv"

# Itera sobre cada entrada e cria o curso
foreach ($turma in $turmas) {

  $nome    = $turma.name
  $alias   = $turma.Aliases
  $section = $turma.section
  $room    = $turma.room
  $teacher = $turma.ownerEmail

  # Cria o curso com os dados fornecidos
  gam create course name "$nome" alias "$alias" section "$section" room "$room" status ACTIVE teacher diogo@colsaofrancisco.com.br

  Write-Host "Curso $nome com o alias $alias criado."
}

Write-Warning "Script finalizado."
