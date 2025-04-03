<#
.SINOPSE
    Adicionar sinopse aqui

.DESCRIÇÃO
    Adicionar descrição detalhada aqui

.EXEMPLO
    .\unsuspendUsers_2.0.ps1

.NOTAS
    Autor: Diogo
    Última atualização: 03/04/2025
#>

## Reativar alunos e/ou funcionários a partir do arquivo CSV

$reativos = Import-Csv "D:\Downloads\reativos.csv"

foreach ($reativo in $reativos) {

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

    # Verifica se a conta está desabilitada
    $adUser = Get-ADUser -Identity $adusername -Properties Enabled

    if ($adUser.Enabled -eq $false) {
        # Marca a conta do aluno como ativa de novo e o coloca no grupo certo
        Set-ADUser -Identity $adusername -Enabled $true
        Write-Host "Conta do Active Directory $adusername do aluno $firstname $surname reativada."

        # Move o usuário para a Unidade Organizacional e adiciona ao grupo dos alunos
        Get-ADUser -Identity $adusername | Move-ADObject -TargetPath $adou
        Write-Host "$adusername movido para a OU $adou"

        Add-ADGroupMember -Identity ALUNOS -Members $adusername
        Write-Host "$adusername adicionado ao grupo ALUNOS."

        # Altera a senha do Active Directory do usuário
        Set-ADAccountPassword -Identity $adusername -NewPassword (ConvertTo-SecureString "$password" -AsPlainText -Force)

        Set-ADUser -Identity $adusername -PasswordNeverExpires $true -ChangePasswordAtLogon $false
        Write-Host "Senha do usuário $adusername alterada para $password"

        # Reativa o usuário no Google Workspace
        gam update user $email firstname "$firstname" lastname "$surname" `
            password "$password" suspended off changepassword on `
            externalid organization $cod `
            org /Alunos/$org `
            Informaes_do_Funcionrio.Data_de_Nascimento $datanascto
        Write-Host "$email reativado no Google Workspace."

        # Adiciona o usuário ao grupo correto no Google Workspace
        gam update group $grupo add member user $email
        Write-Host "$email adicionado ao grupo $grupo."

    }
    else {
        Write-Warning "Conta do Active Directory $adusername já está ativa. Nenhuma ação necessária."
    }
}

Write-Warning "Não se esqueça do Portal SAS e da cantina."
