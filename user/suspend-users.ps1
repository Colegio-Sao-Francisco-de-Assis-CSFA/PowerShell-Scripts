<#
.SINOPSE
  Suspende usuários no Active Directory e Google Workspace.

.DESCRIÇÃO
  Modo individual ou por CSV. Gera senha, suspende no AD e Google,
  move para OU "Contas Suspensas", remove de grupos e salva os grupos
  do AD e do Google em arquivo txt.

.EXEMPLO
  .\suspenderUsuarios.ps1

.NOTAS
  Autor: Diogo
  Última atualização: 01/08/2025
#>

# Força o encoding UTF-8 com BOM para compatibilidade e limpa o terminal
#$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8BOM'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Clear-Host

Add-Type -AssemblyName System.Web

$backupDir = "D:\Scripts\usuarios-suspensos"
if (-not (Test-Path $backupDir)) {
  New-Item -ItemType Directory -Path $backupDir | Out-Null
}

function SuspenderUsuario {
  param (
    [string]$adusername,
    [string]$email
  )

  $password = [System.Web.Security.Membership]::GeneratePassword(10, 2)

  $adUser = Get-ADUser -Filter { SamAccountName -eq $adusername } -Properties EmailAddress
  if (-not $adUser) {
    Write-Warning "Conta AD $adusername não encontrada."
    return
  }
  if (-not $email) {
    $email = $adUser.EmailAddress
  }
  if (-not $email) {
    Write-Warning "Usuário $adusername não tem e-mail cadastrado."
    return
  }

  Set-ADAccountPassword -Identity $adusername -NewPassword (ConvertTo-SecureString "$password" -AsPlainText -Force)
  Set-ADUser -Identity $adusername -ChangePasswordAtLogon $true -PasswordNeverExpires $false -Enabled $false
  Start-Sleep -Seconds 5
  Get-ADUser -Identity $adusername | Move-ADObject -TargetPath "OU=Contas Suspensas,DC=csfa,DC=com,DC=br"
  Write-Warning "AD: $adusername suspenso com senha: $password"

  # Grupos AD
  $gruposAD = Get-ADPrincipalGroupMembership -Identity $adusername | Where-Object { $_.Name -ne 'Usuários do domínio' }
  $gruposADList = $gruposAD | Select-Object -ExpandProperty Name

  # Grupos Google Workspace — CSV simples (sem BOM)
  $tempCsv = "$backupDir\$adusername`_google_groups.csv"
  gam user $email print groups > $tempCsv

  # Junta tudo e salva com UTF-8 sem BOM
  $saida = @()
  $saida += "Grupos AD:"
  $saida += $gruposADList
  $saida += ""
  $saida += "Grupos Google Workspace (via GAM):"
  $saida += Get-Content $tempCsv

  $saidaPath = "$backupDir\$adusername`_grupos_completos.txt"
  $saida | Out-File -Encoding utf8 -FilePath $saidaPath

  # Remove CSV temporário
  Remove-Item $tempCsv -ErrorAction SilentlyContinue

  # Remove de grupos AD
  $gruposAD | Remove-ADGroupMember -Members $adusername -Confirm:$false
  Write-Warning "$adusername removido dos grupos AD. Backup salvo em: $saidaPath"

  # GAM: troca senha, remove de grupos e suspende
  gam update user $email password "$password" nohash changepassword on
  gam user $email delete groups
  gam update user $email suspended on org "/Contas Suspensas"
  Write-Warning "Google: $email suspenso, senha alterada e removido de grupos."
}

$modo = Read-Host "Modo único (U) ou CSV (C)?"

if ($modo.ToUpper() -eq 'U') {
  $adusername = Read-Host "Digite o SamAccountName"
  SuspenderUsuario -adusername $adusername -email ''
}
elseif ($modo.ToUpper() -eq 'C') {
  $caminho = Read-Host "Caminho do CSV (ex: D:\Downloads\suspensos.csv)"
  if (-not (Test-Path $caminho)) {
    Write-Warning "CSV não encontrado."
    return
  }
  $usuarios = Import-Csv $caminho
  foreach ($u in $usuarios) {
    $email = $u.email
    if (-not $email) {
      $found = Get-ADUser -Filter { SamAccountName -eq $u.adusername } -Properties EmailAddress
      $email = $found.EmailAddress
    }
    if ($u.adusername -and $email) {
      SuspenderUsuario -adusername $u.adusername -email $email
    }
    else {
      Write-Warning "Linha inválida ou falta email: $($u | Out-String)"
    }
  }
}
else {
  Write-Warning "Opção inválida. Escolha U ou C."
}

Write-Warning "Fim. Não esqueça SAS, SIGA, ClassApp e Cantina."
