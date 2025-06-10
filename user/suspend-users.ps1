<#
.SINOPSE
    Adicionar sinopse aqui

.DESCRIÇÃO
    Adicionar descrição detalhada aqui

.EXEMPLO
    .\suspendUsers.ps1

.NOTAS
    Autor: Diogo
    Última atualização: 03/04/2025
#>

# Suspender alunos e/ou funcionários a partir do arquivo CSV

$suspensos = Import-Csv "D:\Downloads\suspensos.csv"

# Importar System.Web assembly
Add-Type -AssemblyName System.Web

foreach ($suspenso in $suspensos) {

    $email = $suspenso.email
    $adusername = $suspenso.adusername
    #Gerar senha aleatória com 10 caracteres, sendo 2 caracteres especiais, no mínimo.
    $password = [System.Web.Security.Membership]::GeneratePassword(10, 2)

    #checa se o usuário existe
    if ([bool] (Get-ADUser -Filter { SamAccountName -eq $adusername })) {

        #altera a senha do Active Directory do usuário
        Set-ADAccountPassword `
            -Identity $adusername `
            -NewPassword (ConvertTo-SecureString "$password" -AsPlainText -Force)

        #Muda a senha do usuário e também o suspende
        Set-ADUser `
            -Identity $adusername `
            -ChangePasswordAtLogon $true `
            -PasswordNeverExpires $false `
            -Enabled $false

        Start-Sleep -Seconds 10

        #muda o usuário para a Unidade Organizacional "Contas Suspensas"
        Get-ADUser -Identity "$adusername" | `
                Move-ADObject `
                -TargetPath "OU=Contas Suspensas,DC=csfa,DC=com,DC=br"

        Write-Warning "Conta do Active Directory $adusername suspensa com a senha $password."

        #Remove o usuário de todos os grupos
        Get-ADPrincipalGroupMembership -Identity "$adusername" |`
                Where-Object -Property Name -NE -Value 'Usuários do domínio' |`
                Remove-ADGroupMember -Members "$adusername" -Confirm:$false

        Write-Warning "$adusername removido de todos os grupos."

        #Altera a senha do usuário no Google Workspace
        gam update user $email password "$password" nohash changepassword on

        #Remove o usuário dos grupos no Google Workspace.
        gam user $email delete groups
        Write-Warning "$email removido de todos os grupos."

        #Move o usuário para a Unidade Organizacional "Contas Suspensas" e suspende o usuário no Google Workspace.
        gam update user $email `
            suspended on `
            org "/Contas Suspensas"

        Write-Warning "$email suspenso, movido e senha alterada no Google Workspace."

    }

    else {

        Write-Warning "A conta $adusername com o email $email não existe."

    }
}

Write-Warning "Script finalizado, não se esqueça do Portal SAS, SIGA, Classapp e cantina."