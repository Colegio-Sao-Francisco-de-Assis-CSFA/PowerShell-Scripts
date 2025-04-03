<#
.SINOPSE
    Adicionar sinopse aqui

.DESCRIÇÃO
    Adicionar descrição detalhada aqui

.EXEMPLO
    .\updateStudentPhotos.ps1

.NOTAS
    Autor: Diogo
    Última atualização: 03/04/2025
#>

﻿<# 
    Script: Atualização de fotos dos alunos no Google Workspace
    Autor: Diogo
    Descrição: 
        Este script PowerShell atualiza as fotos dos usuários (alunos) no Google Workspace 
        com base em um arquivo CSV contendo os e-mails e nomes dos alunos, e em uma pasta com 
        as fotos nomeadas conforme o e-mail do aluno.

    Requisitos:
        - O GAM (Google Apps Manager) deve estar instalado e configurado.
        - O usuário executando o script deve ter permissões para alterar fotos de usuários no domínio.
        - A pasta com as fotos deve conter os arquivos no formato: email@dominio.com.jpg
        - O arquivo CSV deve conter pelo menos as colunas: "email" e "NOME" (com esses títulos).

    Instruções:
        1. Atualize o caminho para o arquivo CSV e a pasta com as fotos conforme necessário.
        2. Execute o script com permissões adequadas no PowerShell.

    Observação:
        Fotos ausentes serão registradas como aviso (warning) no terminal.
#>

# Limpa o terminal
Clear-Host

#Atualizar fotos dos alunos no Gsuite a partir do arquivo CSV

$alunos = Import-Csv "D:\Downloads\todosalunos.csv"
$gsuitepics = "D:\Downloads\fotos school picture - alunos\gsuite"
$ext = "jpg"

foreach ($aluno in $alunos) {

  $email = $aluno.email
  $nome = $aluno.NOME

  if (Test-Path -Path "$gsuitepics\$email.$ext" -PathType Leaf) {

    gam user $email update photo $gsuitepics\$email.$ext

    Write-Host "Foto do Google Workspace do usuário $nome alterada."

  }
  else {

    Write-Warning "Arquivo $gsuitepics\$email.$ext não existe."
  } 
}

Write-Warning "Script finalizado."