#Reativar alunos e/ou funcionários a partir do arquivo CSV

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

#Marca a conta do aluno como ativa de novo e o coloca no grupo certo
Set-ADUser `
-Identity $adusername `-Enabled $true `

Write-Warning "Conta do Active Directory $adusername do aluno $firstname $surname reativada."

#muda o usuário para a Unidade Organizacional e adiciona ao grupo dos alunos
Get-ADUser -Identity $adusername | `Move-ADObject `-TargetPath $adou

Write-Warning "$adusername movido para a OU $adou"

Add-ADGroupMember -Identity ALUNOS -Members $adusername

Write-Warning "$adusername adicionado ao grupo ALUNOS."

#altera a senha do Active Directory do usuário
Set-ADAccountPassword `
-Identity $adusername `
-NewPassword (ConvertTo-SecureString "$password" -AsPlainText -Force)

Set-ADUser `
-Identity $adusername `-PasswordNeverExpires $true `
-ChangePasswordAtLogon $false

Write-Warning "Senha do usuário $adusername alterada para $password"

gam update user $email firstname "$firstname" lastname "$surname" `
password "$password" suspended off changepassword on `externalid organization $cod `org /Alunos/$org `
Informaes_do_Funcionrio.Data_de_Nascimento $datanascto

Write-Warning "$email reativado no Google Workspace."

gam update group $grupo add member user $email

Write-Warning "$email adicionado ao grupo $grupo."

}

Write-Warning "Não se esqueça do Portal SAS e da cantina."