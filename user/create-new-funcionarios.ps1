<#
.SINOPSE
    Adicionar sinopse aqui

.DESCRIÇÃO
    Adicionar descrição detalhada aqui

.EXEMPLO
    .\createNewFuncionarios.ps1

.NOTAS
    Autor: Diogo
    Última atualização: 03/04/2025
#>

﻿#Criar alunos novos a partir do arquivo CSV

$funcionarios = Import-Csv "D:\Downloads\funcnovos2601.csv"

foreach ($funcionario in $funcionarios) {

$firstname = $funcionario.firstname
$surname = $funcionario.surname
$email = $funcionario.email
$org = $funcionario.org
$adusername = $funcionario.adusername
$adou = $funcionario.ADOU
$adgroup = $funcionario.ADgroup

if ([bool] (Get-ADUser -Filter { SamAccountName -eq $adusername })) {

Write-Warning "A conta $adusername do(a) funcionário(a) $firstname $surname já existe." }

else {

New-ADUser `
-SamAccountName $adusername `
-GivenName "$firstname" -Surname "$surname" `
-Name "$firstname $surname" `
-UserPrincipalName "$adusername@csfa.com.br" `
-Path $adou `
-EmailAddress $email `
-AccountPassword (ConvertTo-SecureString "Mudar123" -AsPlainText -Force) -ChangePasswordAtLogon $true -PasswordNeverExpires $false `
-Enabled $true
#-EmployeeID $cod `

Write-Warning "Conta do Active Directory $adusername criada para o funcionário $firstname $surname."

Add-ADGroupMember -Identity $adgroup -Members $adusername

Write-Warning "$adusername adicionado ao grupo $adgroup."

gam create user $email `
firstname "$firstname" lastname "$surname" `
password "$password" suspended off changepassword on `
org "/$org"
#externalid organization $cod
#Informaes_do_Funcionrio.Data_de_Nascimento $datanascto

Write-Warning "$email criado no Google Workspace."

#gam update group $grupo add member user $email

#Write-Warning "$email adicionado ao grupo $grupo."

}
}