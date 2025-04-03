<#
.SINOPSE
    Adicionar sinopse aqui

.DESCRIÇÃO
    Adicionar descrição detalhada aqui

.EXEMPLO
    .\moveItemsCreateFolders.ps1

.NOTAS
    Autor: Diogo
    Última atualização: 03/04/2025
#>

﻿<#
    Script: Organização e renomeação de fotos de alunos por turma
    Autor: Diogo
    Descrição:
        Este script lê um arquivo CSV contendo informações dos alunos
        (curso, série, turma, número e nome), e move os arquivos de foto
        para subpastas específicas com base na estrutura: CURSO\SÉRIE TURMA.
        Ao mover o arquivo, ele também renomeia a foto com o nome do aluno.

    Requisitos:
        - As fotos devem estar inicialmente na pasta raiz definida em $pastaRaiz.
        - Os arquivos devem estar nomeados com o valor da coluna NUMERO (ex: 123.jpg).
        - O arquivo CSV deve conter as colunas: CURSO, SERIE, TURMA, NUMERO, NOME.

    Observação:
        - Se a pasta de destino ainda não existir, ela será criada automaticamente.
        - A nova foto será nomeada como "NOME.jpg", com base na coluna NOME do CSV.
        - Se já existir uma foto com o mesmo nome na pasta de destino, o script adiciona um sufixo numérico (_1, _2...) para evitar sobrescrever.
#>

# Limpa o terminal
Clear-Host

# Caminho para a pasta raiz onde estão as fotos dos alunos
$pastaRaiz = "D:\Downloads\fotos school picture - alunos\arquivo"

# Caminho para o arquivo CSV
$caminhoCsv = "D:\Downloads\todosalunos.csv"

# Lê os dados do CSV
$alunos = Import-Csv -Path $caminhoCsv

# Extensão dos arquivos de imagem
$extensao = "jpg"

# Loop por cada linha do CSV
foreach ($aluno in $alunos) {

  # Extrai os dados do aluno
  $curso = $aluno.CURSO
  $serie = $aluno.SERIE
  $turma = $aluno.TURMA
  $numero = $aluno.NUMERO
  $nome = $aluno.NOME

  # Monta o caminho da subpasta de destino: CURSO\SÉRIE TURMA
  $pastaDestino = Join-Path -Path $pastaRaiz -ChildPath $curso
  $pastaDestino = Join-Path -Path $pastaDestino -ChildPath "$serie $turma"

  # Cria a pasta de destino se ela não existir
  if (-not (Test-Path -Path $pastaDestino -PathType Container)) {
    New-Item -Path $pastaDestino -ItemType Directory | Out-Null
  }

  # Caminho completo da foto original
  $fotoOrigem = Join-Path -Path $pastaRaiz -ChildPath "$numero.$extensao"

  # Caminho base do destino com nome do aluno
  $nomeBase = $nome
  $fotoDestino = Join-Path -Path $pastaDestino -ChildPath "$nomeBase.$extensao"
  $contador = 1

  # Verifica se já existe uma foto com o mesmo nome e incrementa sufixo se necessário
  while (Test-Path -Path $fotoDestino -PathType Leaf) {
    $nomeComSufixo = "$nomeBase" + "_$contador"
    $fotoDestino = Join-Path -Path $pastaDestino -ChildPath "$nomeComSufixo.$extensao"
    $contador++
  }

  # Move e renomeia a foto, se ela existir
  if (Test-Path -Path $fotoOrigem -PathType Leaf) {
    Move-Item -Path $fotoOrigem -Destination $fotoDestino
    Write-Host "Foto de '$nome' movida para '$pastaDestino' como '$(Split-Path $fotoDestino -Leaf)'."
  }
  else {
    Write-Warning "Foto '$numero.$extensao' não encontrada para o aluno '$nome'."
  }
}

Write-Host "`nProcesso concluído com sucesso."
