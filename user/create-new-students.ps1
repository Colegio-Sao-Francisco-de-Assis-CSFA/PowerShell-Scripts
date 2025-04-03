<#
.SINOPSE
    Adicionar sinopse aqui

.DESCRIÇÃO
    Adicionar descrição detalhada aqui

.EXEMPLO
    .\createNewStudents.ps1

.NOTAS
    Autor: Diogo
    Última atualização: 03/04/2025
#>

﻿#Criar alunos novos a partir do arquivo CSV

$alunos = Import-Csv "D:\Downloads\alunosnovos.csv"

foreach ($aluno in $alunos) {

$firstname = $aluno.firstname
$surname = $aluno.surname
$cod = $aluno.NUMERO
$email = $aluno.email
$org = $aluno.org
$grupo = $aluno.grupo
$adusername = $aluno.adusername
$adou = $aluno.ADOU
$password = $aluno.Password
$datanascto = $aluno.DataNascto
$alias = "$adusername@colsaofrancisco.com.br"

if ([bool] (Get-ADUser -Filter { SamAccountName -eq $adusername })) {

Write-Warning "A conta $adusername do(a) aluno(a) $firstname $surname - $cod já existe." }

else {

New-ADUser `
-SamAccountName $adusername `
-GivenName "$firstname" -Surname "$surname" `
-Name "$firstname $surname" `
-DisplayName "$firstname $surname" `
-UserPrincipalName "$adusername@csfa.com.br" `
-Path $adou `
-EmailAddress $email `
-EmployeeID $cod `
-AccountPassword (ConvertTo-SecureString $password -AsPlainText -Force) -ChangePasswordAtLogon $false -PasswordNeverExpires $true `
-Enabled $true

Write-Host "Conta do Active Directory $adusername criada para o aluno $firstname $surname."

Add-ADGroupMember -Identity ALUNOS -Members $adusername

Write-Host "$adusername adicionado ao grupo ALUNOS."

gam create user $email `
firstname "$firstname" lastname "$surname" `
password "$password" suspended off changepassword on `
externalid organization $cod `
org /Alunos/$org `
Informaes_do_Funcionrio.Data_de_Nascimento $datanascto

Write-Host "$email criado no Google Workspace."

gam update group $grupo add member user $email

Write-Host "$email adicionado ao grupo $grupo."

gam create alias $alias user $email

Write-Host "Alias $alias criado."

}
}

Write-Warning "Não se esqueça do Portal SAS e da cantina."