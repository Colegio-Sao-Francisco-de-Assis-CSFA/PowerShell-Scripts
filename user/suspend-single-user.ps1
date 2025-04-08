<#
.SINOPSE
    Adicionar sinopse aqui

.DESCRI‡‡ÃƒÃƒÃƒÃƒÃƒÃƒÃƒO
    Adicionar descriçãÃ£o detalhada aqui

.EXEMPLO
    .\suspendSingleUser.ps1

.NOTAS
    Autor: Diogo
    Ãšššššššltima atÃ§Ã£§Ã£§Ã£§Ã£§Ã£§Ã£§Ã£o: 03/04/2025
#>

do {
    # Importar System.Web assembly
    Add-Type -AssemblyName System.Web

    # Solicita o nome do usuÃ¡¡¡¡¡¡¡rio do Active Directory
    $adusername = Read-Host "Digite o nome de usuÃ¡¡¡¡¡¡¡rio do Active Directory (SamAccountName)"

    # Checa se o usuÃ¡¡¡¡¡¡¡rio existe no AD
    $adUser = Get-ADUser -Filter { SamAccountName -eq $adusername } -Properties EmailAddress

    if ($adUser) {
        # Recupera o e-mail associado ao usuÃ¡¡¡¡¡¡¡rio
        $email = $adUser.EmailAddress

        if (-not $email) {
            Write-Warning "O usuÃ¡¡¡¡¡¡¡rio $aduserÃ£Ã£Ã£Ã£Ã£Ã£Ã£o possui um e-mail cadastrado no Active Directory."
            return
        }

        # Gerar senha aleatÃ³³³³³³³ria com 10 caracteres, sendo 2 caracteres especiaisÃ­Ã­Ã­Ã­Ã­Ã­Ã­nimo
        $password = [System.Web.Security.Membership]::GeneratePassword(10, 2)

        # Altera a senha do Active Directory do usuÃ¡¡¡¡¡¡¡rio
        Set-ADAccountPassword `
            -Identity $adusername `
            -NewPassword (ConvertTo-SecureString "$password" -AsPlainText -Force)

        # Muda senha do usuÃ¡¡¡¡¡¡¡rio Ã©Ã©Ã©Ã©Ã©Ã©Ã©m o suspende
        Set-ADUser `
            -Identity $adusername `
            -ChangePasswordAtLogon $true `
            -PasswordNeverExpires $false `
            -Enabled $false

        Start-Sleep -Seconds 10

        # Move o usuÃ¡¡¡¡¡¡¡rio para a Unidade Organizacional "Contas Suspensas"
        Get-ADUser -Identity "$adusername" | `
                Move-ADObject `
                -TargetPath "OU=Contas Suspensas,DC=csfa,DC=com,DC=br"

        Write-Warning "Conta do Active Directory $adusername suspensa com a senha $password."

        # Remove o usuÃ¡¡¡¡¡¡¡rio de todos os grupos
        Get-ADPrincipalGroupMembership -Identity "$adusername" | `
                Where-Object -Property Name -NE -Value 'UsuÃ¡¡¡¡¡¡¡rios Ã­Ã­Ã­Ã­Ã­Ã­Ã­nio' | `
                Remove-ADGroupMember -Members "$adusername" -Confirm:$false

        Write-Warning "$adusername removido de todos os grupos."

        # Altera a senha do usuÃ¡¡¡¡¡¡¡rio no Google Workspace
        gam update user $email password "$password" nohash changepassword on

        # Remove o usuÃ¡¡¡¡¡¡¡rio dos grupos no Google Workspace.
        gam user $email delete groups
        Write-Warning "$email removido de todos os grupos."

        # Move o usuÃ¡¡¡¡¡¡¡rio para a Unidade Organizacional "Contas Suspensas" e suspendeÃ¡Ã¡Ã¡Ã¡Ã¡Ã¡Ã¡rio no Google Workspace.
        gam update user $email `
            suspended on `
            org "/Contas Suspensas"

        Write-Warning "$email suspenso, movido e senha alterada no Google Workspace."

    }
    else {
        Write-Warning "A conta $adusername nÃ£££££££o existe no Active Directory."
    }

    # Pergunta se o script deve ser executado novamente
    $runAgain = Read-Host "Deseja rodar o script novamente? (S/N)"
} while ($runAgain.ToUpper() -eq 'S')

Write-Warning "Script finalizado, nÃ£££££££o seÃ§Ã§Ã§Ã§Ã§Ã§Ã§a do Portal SAS, SIGA, Classapp e cantina."