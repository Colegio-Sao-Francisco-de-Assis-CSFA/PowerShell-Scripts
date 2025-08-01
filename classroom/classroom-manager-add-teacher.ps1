<#
  .SINOPSE
    Adiciona o professor responsável a cada turma no Google Classroom.

  .DESCRIÇÃO
    Este script lê um arquivo CSV contendo as informações das turmas e adiciona o professor responsável
    utilizando o GAM (Google Apps Manager). Para cada turma, o script adiciona e atualiza o professor conforme o ID.

  .EXEMPLO
    .\classroom-manager-add-teacher.ps1

  .NOTAS
    Autor: Diogo
    Última atualização: 08/04/2025
#>

# Força o encoding UTF-8 com BOM para compatibilidade e limpa o terminal
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8BOM'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Clear-Host

# Importa as turmas a partir de um arquivo CSV localizado na pasta Downloads
$turmas = Import-Csv "D:\Downloads\classroom-manager.csv"

# Itera sobre cada turma no CSV
foreach ($turma in $turmas) {

  $nome = $turma.name
  $id = $turma.id
  $teacher = $turma.ownerEmail

  # Adiciona o professor ao curso
  gam course $id add teacher $teacher

  # Garante que o professor seja definido como principal
  gam update course $id teacher $teacher

  Write-Warning "Professor $teacher adicionado ao curso $nome."
}

Write-Warning "Script finalizado."
