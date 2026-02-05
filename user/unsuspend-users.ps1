# Força o encoding UTF-8 com BOM para compatibilidade e limpa o terminal
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8BOM'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Clear-Host

<#
.SINOPSE
  Reativa alunos no Active Directory e no Google Workspace a partir de um CSV.

.DESCRIÇÃO
  Este script lê um arquivo CSV com alunos reativos, verifica se a conta está
  desabilitada no Active Directory e, caso esteja, reativa o usuário, move para
  a OU correta, ajusta grupos, redefine senha e reativa o usuário no Google Workspace.

.EXEMPLO
  .\reativar-alunos.ps1

.NOTAS
  Autor: Diogo
  Criado em: 03/04/2025
  Atualizado em: 02/02/2026

  Changelog:
    - 03/04/2025 v1.0 - Criação do script
    - 02/02/2026 v1.1 - Correção do Move-ADObject e padronização de output
#>

# Importa o CSV com os alunos reativos
$reativos = Import-Csv "C:\Users\dnunes\Downloads\reativos.csv"

# Contadores para estatística final
$total = 0
$reativados = 0
$ativos = 0

foreach ($reativo in $reativos) {

  $total++

  # Dados do aluno
  $firstname = $reativo.firstname
  $surname = $reativo.surname
  $cod = $reativo.NUMERO
  $email = $reativo.email
  $org = $reativo.org
  $grupo = $reativo.grupo
  $adusername = $reativo.adusername
  $adou = $reativo.ADOU
  $password = $reativo.Password
  $datanascto = $reativo.DataNascto

  # Busca o usuário no AD
  $adUser = Get-ADUser -Identity $adusername -Properties Enabled, DistinguishedName

  if ($adUser.Enabled -eq $false) {

    Write-Host "🔄 Reativando usuário $adusername ($firstname $surname)..." -ForegroundColor Cyan

    # Reativa a conta no AD
    Set-ADUser -Identity $adusername -Enabled $true

    # Move para a OU correta
    Move-ADObject -Identity $adUser.DistinguishedName -TargetPath $adou

    # Adiciona ao grupo ALUNOS
    Add-ADGroupMember -Identity ALUNOS -Members $adusername

    # Redefine senha
    Set-ADAccountPassword `
      -Identity $adusername `
      -NewPassword (ConvertTo-SecureString $password -AsPlainText -Force)

    Set-ADUser `
      -Identity $adusername `
      -PasswordNeverExpires $true `
      -ChangePasswordAtLogon $false

    # Reativa no Google Workspace
    gam update user $email `
      firstname "$firstname" `
      lastname "$surname" `
      password "$password" `
      suspended off `
      changepassword on `
      externalid organization $cod `
      org /Alunos/$org `
      Informaes_do_Funcionrio.Data_de_Nascimento $datanascto

    # Adiciona ao grupo correto no Google Workspace
    gam update group $grupo add member user $email

    Write-Host "✅ Usuário $adusername reativado com sucesso." -ForegroundColor Green
    $reativados++

  }
  else {

    Write-Host "ℹ️ $adusername já está ativo. Nenhuma ação necessária." -ForegroundColor Yellow
    $ativos++
  }
}

# Resumo final
Write-Host ""
Write-Host "📊 RESUMO FINAL" -ForegroundColor Cyan
Write-Host "Total de registros: $total"
Write-Host "Reativados: $reativados"
Write-Host "Já ativos: $ativos"

Write-Warning "⚠️ Não se esqueça do Portal SAS e da cantina."
