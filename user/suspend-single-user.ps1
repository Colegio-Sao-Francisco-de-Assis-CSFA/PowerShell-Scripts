<#
.SINOPSE
    Suspende uma conta de usuário no Active Directory e Google Workspace.

.DESCRIÇÃO
    Este script redefine a senha do usuário, suspende sua conta no AD e no Google Workspace,
    move a conta para a OU "Contas Suspensas", remove o usuário de todos os grupos e exibe a nova senha gerada.

.EXEMPLO
    .\suspend-single-user.ps1

.NOTAS
    Autor: Diogo
    Última atualização: 03/04/2025
#>

do {
  # Importar System.Web assembly
  Add-Type -AssemblyName System.Web

  # Solicita o nome do usuário do Active Directory
  $adusername = Read-Host "Digite o nome de usuário do Active Directory (SamAccountName)"

  # Checa se o usuário existe no AD
  $adUser = Get-ADUser -Filter { SamAccountName -eq $adusername } -Properties EmailAddress

  if ($adUser) {
    # Recupera o e-mail associado ao usuário
    $email = $adUser.EmailAddress

    if (-not $email) {
      Write-Warning "O usuário $adusername não possui um e-mail cadastrado no Active Directory."
      return
    }

    # Gerar senha aleatória com 10 caracteres, sendo 2 caracteres especiais no mínimo
    $password = [System.Web.Security.Membership]::GeneratePassword(10, 2)

    # Altera a senha do Active Directory do usuário
    Set-ADAccountPassword `
      -Identity $adusername `
      -NewPassword (ConvertTo-SecureString "$password" -AsPlainText -Force)

    # Muda senha do usuário e o suspende
    Set-ADUser `
      -Identity $adusername `
      -ChangePasswordAtLogon $true `
      -PasswordNeverExpires $false `
      -Enabled $false

    Start-Sleep -Seconds 10

    # Move o usuário para a Unidade Organizacional "Contas Suspensas"
    Get-ADUser -Identity "$adusername" | `
        Move-ADObject `
        -TargetPath "OU=Contas Suspensas,DC=csfa,DC=com,DC=br"

    Write-Warning "Conta do Active Directory $adusername suspensa com a senha $password."

    # Remove o usuário de todos os grupos
    Get-ADPrincipalGroupMembership -Identity "$adusername" | `
        Where-Object -Property Name -NE -Value 'Usuários padrão' | `
        Remove-ADGroupMember -Members "$adusername" -Confirm:$false

    Write-Warning "$adusername removido de todos os grupos."

    # Altera a senha do usuário no Google Workspace
    gam update user $email password "$password" nohash changepassword on

    # Remove o usuário dos grupos no Google Workspace
    gam user $email delete groups
    Write-Warning "$email removido de todos os grupos."

    # Move e suspende o usuário no Google Workspace
    gam update user $email `
      suspended on `
      org "/Contas Suspensas"

    Write-Warning "$email suspenso, movido e senha alterada no Google Workspace."

  }
  else {
    Write-Warning "A conta $adusername não existe no Active Directory."
  }

  # Pergunta se o script deve ser executado novamente
  $runAgain = Read-Host "Deseja rodar o script novamente? (S/N)"
} while ($runAgain.ToUpper() -in @('S', 'Y'))

Write-Warning "Script finalizado. Não se esqueça de desativar no Portal SAS, SIGA, ClassApp e cantina."
