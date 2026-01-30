<#
.SINOPSE
Cria turmas no Google Classroom com os parâmetros definidos em um CSV.

.DESCRIÇÃO
Este script importa um arquivo CSV contendo os dados das turmas (nome,alias, seção, sala e professor)
e cria as turmas utilizando o GAM, definindo o status como ativo.

.EXEMPLO
.\classroom-manager-criar.ps1

.NOTAS
Autor: Diogo
Última atualização: 08/04/2025
#>

# Força o encoding UTF-8 com BOM para compatibilidade e limpa o terminal
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8BOM'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Clear-Host

# Importa as turmas a partir de um arquivo CSV
$turmas = Import-Csv "C:\Users\dnunes\Downloads\classroom_manager.csv"

# Itera sobre cada entrada e cria o curso
foreach ($turma in $turmas) {

  $nome = $turma.name
  $alias = $turma.Aliases
  $section = $turma.section
  $room = $turma.room

  # Cria o curso com os dados fornecidos
  gam create course name "$nome" alias "$alias" section "$section" room "$room" status ACTIVE teacher diogo@colsaofrancisco.com.br

  Write-Host "Curso $nome com o alias $alias criado."
}

Write-Warning "Script finalizado."
