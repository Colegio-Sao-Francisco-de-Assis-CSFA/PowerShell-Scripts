# Força o encoding UTF-8 com BOM para compatibilidade e limpa o terminal
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8BOM'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Clear-Host

<#
.SINOPSE
  Cria novos alunos no Active Directory e no Google Workspace a partir de um arquivo CSV.

.DESCRIÇÃO
  Este script lê um arquivo CSV contendo os dados dos alunos e realiza:
  - Criação do usuário no Active Directory
  - Inclusão no grupo ALUNOS
  - Criação do usuário no Google Workspace via GAM
  - Inclusão do usuário em grupos do Google
  - Criação de alias de e-mail institucional

  O script valida previamente se o usuário já existe no Active Directory
  para evitar duplicidades.

.EXEMPLO
  .\create-new-students.ps1

.NOTAS
  Autor: Diogo
  Criado em: 03/04/2025
  Atualizado em: 03/04/2025

  Changelog:
    - 03/04/2025 v1.0 - Criação do script
    - 03/04/2025 v1.1 - Padronização, comentários e melhoria de outputs
#>

# ==============================
# CONFIGURAÇÕES INICIAIS
# ==============================

# Caminho fixo do CSV conforme diretriz do projeto
$csvPath = "C:\Users\dnunes\Downloads\alunosnovos.csv"

# Importa os alunos do CSV
$alunos = Import-Csv $csvPath

# Contadores para estatística final
$total = 0
$criados = 0
$existentes = 0
$erros = 0

Write-Host "Iniciando criação de alunos..." -ForegroundColor Cyan
Write-Host "Arquivo CSV: $csvPath"
Write-Host "---------------------------------------------"

foreach ($aluno in $alunos) {

  $total++

  # ==============================
  # VARIÁVEIS DO CSV
  # ==============================

  $firstname = $aluno.firstname
  $surname = $aluno.surname
  $cod = $aluno.NUMERO
  $email = $aluno.email
  $org = $aluno.org
  $grupo = $aluno.grupo
  $adusername = $aluno.adusername
  $adou = $aluno.ADOU
  $password = $aluno.Password
  $datanascto = $aluno.DataNascto

  # Alias padrão institucional
  $alias = "$adusername@colsaofrancisco.com.br"

  Write-Host ""
  Write-Host "▶ Processando aluno: $firstname $surname ($adusername)" -ForegroundColor Yellow

  try {

    # ==============================
    # VALIDA SE O USUÁRIO JÁ EXISTE NO AD
    # ==============================

    $usuarioAD = Get-ADUser -Filter { SamAccountName -eq $adusername } -ErrorAction SilentlyContinue

    if ($usuarioAD) {

      Write-Warning "Usuário $adusername já existe no Active Directory."
      $existentes++
      continue
    }

    # ==============================
    # CRIA USUÁRIO NO ACTIVE DIRECTORY
    # ==============================

    New-ADUser `
      -SamAccountName $adusername `
      -GivenName $firstname `
      -Surname $surname `
      -Name "$firstname $surname" `
      -DisplayName "$firstname $surname" `
      -UserPrincipalName "$adusername@csfa.com.br" `
      -Path $adou `
      -EmailAddress $email `
      -EmployeeID $cod `
      -AccountPassword (ConvertTo-SecureString $password -AsPlainText -Force) `
      -ChangePasswordAtLogon $false `
      -PasswordNeverExpires $true `
      -Enabled $true

    Write-Host "✔ Usuário $adusername criado no Active Directory."

    # ==============================
    # ADICIONA AO GRUPO ALUNOS (AD)
    # ==============================

    Add-ADGroupMember -Identity "ALUNOS" -Members $adusername

    Write-Host "✔ Usuário $adusername adicionado ao grupo ALUNOS."

    # ==============================
    # CRIA USUÁRIO NO GOOGLE WORKSPACE
    # ==============================

    gam create user $email `
      firstname "$firstname" `
      lastname "$surname" `
      password "$password" `
      suspended off `
      changepassword on `
      externalid organization $cod `
      org "/Alunos/$org" `
      Informaes_do_Funcionrio.Data_de_Nascimento $datanascto `
      > $null

    Write-Host "✔ Usuário $email criado no Google Workspace."

    # ==============================
    # ADICIONA AO GRUPO DO GOOGLE
    # ==============================

    gam update group $grupo add member user $email > $null

    Write-Host "✔ Usuário $email adicionado ao grupo $grupo."

    # ==============================
    # CRIA ALIAS DE E-MAIL
    # ==============================

    gam create alias $alias user $email > $null

    Write-Host "✔ Alias $alias criado."

    $criados++

  }
  catch {

    Write-Error "Erro ao processar o aluno $firstname $surname ($adusername)."
    Write-Error $_
    $erros++
  }
}

# ==============================
# RESUMO FINAL
# ==============================

Write-Host ""
Write-Host "============================================="
Write-Host "Processamento finalizado" -ForegroundColor Cyan
Write-Host "Total no CSV        : $total"
Write-Host "Criados com sucesso : $criados" -ForegroundColor Green
Write-Host "Já existentes      : $existentes" -ForegroundColor Yellow
Write-Host "Erros              : $erros" -ForegroundColor Red
Write-Host "============================================="

Write-Warning "Não se esqueça do Portal SAS e da cantina."
