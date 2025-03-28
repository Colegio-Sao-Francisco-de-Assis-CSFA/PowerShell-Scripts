$users = Import-Csv "D:\Downloads\updateemails.csv"

foreach ($user in $users) {

Set-ADUser -Identity $user.SamAccountName -EmailAddress $user.EmailAddress

Write-Host "Usuário $user.SamAccountName atualizado com o e-mail $user.EmailAddress"

}