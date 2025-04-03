<#
.SINOPSE
    Adicionar sinopse aqui

.DESCRIÇÃO
    Adicionar descrição detalhada aqui

.EXEMPLO
    .\formandos3em.ps1

.NOTAS
    Autor: Diogo
    Última atualização: 03/04/2025
#>

﻿# Atualizar alunos da 3ª EM para o domínio csfaparasempre.com.br
$formandos = Import-Csv "D:\Downloads\3em.csv"

foreach ($formando in $formandos) {

$email = $formando.email
$novoemail = $formando.emailnovo
$adusername = $formando.adusername

#checa se o usuário existe
if ([bool] (Get-ADUser -Filter { SamAccountName -eq $adusername })) {

#muda o usuário para a Unidade Organizacional "Contas Suspensas"
Get-ADUser -Identity $adusername | Move-ADObject -TargetPath "OU=Formandos,OU=Alunos,OU=Acesso Nível 1,DC=csfa,DC=com,DC=br"

Write-Host "Conta do Active Directory $adusername movida para OU Formandos."

#comandos do GAM
gam user $email delete groups
Write-Host "$email removido de todos os grupos antigos"

gam update user $email org "/CSFA para sempre/Alunos" email $novoemail
Write-Host "$email alterado para $novoemail e movido para a OU CSFA para sempre"

gam update group todos@csfaparasempre.com.br add member user $novoemail

Write-Host "$novoemail adicionado ao grupo CSFA para sempre"

}

else {
Write-Warning "O usuário $adusername não existe."
}
}