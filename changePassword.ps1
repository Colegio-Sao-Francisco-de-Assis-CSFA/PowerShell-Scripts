#Mudar a senha do AD dos usuários

$servico = "email" #Coloque aqui se quer alterar a senha do AD ou do e-mail do usuário, as variáveis possíveis são "ad", "email" ou "ambos"
$tipousuario = "func" #Aluno ou funcionário?
$adusername = "cloves.neto" #Coloque aqui o usuário do Active Directory
$email = "manuela.melo@aluno.colsaofrancisco.com.br" #Coloque aqui o e-mail do usuário
$password = "Mudar123" #Coloque aqui a senha para ser utilizada

if ($servico -eq "ad") {

Set-ADAccountPassword `
-Identity $adusername `
-NewPassword (ConvertTo-SecureString "$password" -AsPlainText -Force)

Set-ADUser `
-Identity $adusername `-PasswordNeverExpires $true `
-ChangePasswordAtLogon $false

Write-Warning "Senha do Active Directory do usuário $adusername alterada para $password."
}

elseif ($servico -eq "email") {
gam update user $email password $password changepassword on
Write-Warning "Senha do Google do usuário $email alterada para $password."
}

elseif ($servico -eq "ambos") {
Set-ADAccountPassword `
-Identity $adusername `
-NewPassword (ConvertTo-SecureString "$password" -AsPlainText -Force)

Set-ADUser `
-Identity $adusername `-PasswordNeverExpires $false `
-ChangePasswordAtLogon $true

Write-Warning "Senha do Active Directory do usuário $adusername alterada para $password."

gam update user $email password $password changepassword on
Write-Warning "Senha do usuário $email alterada para $password no Google."
}