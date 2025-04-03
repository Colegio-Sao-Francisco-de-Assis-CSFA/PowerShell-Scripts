<#
.SINOPSE
    Adicionar sinopse aqui

.DESCRIÇÃO
    Adicionar descrição detalhada aqui

.EXEMPLO
    .\suspendSingleUser.ps1

.NOTAS
    Autor: Diogo
    Última atualização: 03/04/2025
#>

﻿do {
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

        # Gerar senha aleatória com 10 caracteres, sendo 2 caracteres especiais, no mínimo
        $password = [System.Web.Security.Membership]::GeneratePassword(10, 2)

        # Altera a senha do Active Directory do usuário
        Set-ADAccountPassword `
            -Identity $adusername `
            -NewPassword (ConvertTo-SecureString "$password" -AsPlainText -Force)

        # Muda senha do usuário e também o suspende
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
        Get-AdPrincipalGroupMembership -Identity "$adusername" | `
            Where-Object -Property Name -Ne -Value 'Usuários do domínio' | `
            Remove-AdGroupMember -Members "$adusername" -Confirm:$false

        Write-Warning "$adusername removido de todos os grupos."

        # Altera a senha do usuário no Google Workspace
        gam update user $email password "$password" nohash changepassword on

        # Remove o usuário dos grupos no Google Workspace.
        gam user $email delete groups
        Write-Warning "$email removido de todos os grupos."

        # Move o usuário para a Unidade Organizacional "Contas Suspensas" e suspende o usuário no Google Workspace.
        gam update user $email `
            suspended on `
            org "/Contas Suspensas"

        Write-Warning "$email suspenso, movido e senha alterada no Google Workspace."

    } else {
        Write-Warning "A conta $adusername não existe no Active Directory."
    }

    # Pergunta se o script deve ser executado novamente
    $runAgain = Read-Host "Deseja rodar o script novamente? (S/N)"
} while ($runAgain.ToUpper() -eq 'S')

Write-Warning "Script finalizado, não se esqueça do Portal SAS, SIGA, Classapp e cantina."