<#
.SINOPSE
    Adicionar sinopse aqui

.DESCRIÇÃO
    Adicionar descrição detalhada aqui

.EXEMPLO
    .\updateUserOU.ps1

.NOTAS
    Autor: Diogo
    Última atualização: 03/04/2025
#>

﻿# Alterar a Unidade Organizacional (OU) de usuários no Active Directory e Google Workspace a partir do arquivo CSV

$usuarios = Import-Csv "D:\Downloads\todosalunos.csv"

foreach ($usuario in $usuarios) {

    $firstname = $usuario.firstname
    $surname = $usuario.surname
    $cod = $usuario.NUMERO
    $email = $usuario.email
    $org = $usuario.org
    $adusername = $usuario.adusername
    $adou = $usuario.ADOU

    # Verifica se a conta existe no AD
    $adUser = Get-ADUser -Identity $adusername -Properties DistinguishedName -ErrorAction SilentlyContinue

    if ($adUser) {
        # Move o usuário para a nova Unidade Organizacional no Active Directory
        Get-ADUser -Identity $adusername | Move-ADObject -TargetPath $adou
        Write-Host "$adusername movido para a OU $adou no Active Directory."

        # Atualiza a Unidade Organizacional no Google Workspace
        gam update user $email org "/Alunos/$org"
        Write-Host "$email movido para a OU /Alunos/$org no Google Workspace."

    } else {
        Write-Warning "Usuário $adusername não encontrado no Active Directory. Nenhuma alteração feita."
    }
}

Write-Warning "Processo concluído."
