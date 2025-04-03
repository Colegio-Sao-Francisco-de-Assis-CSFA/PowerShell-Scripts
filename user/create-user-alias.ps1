<#
.SINOPSE
    Adicionar sinopse aqui

.DESCRIÇÃO
    Adicionar descrição detalhada aqui

.EXEMPLO
    .\createUserAlias.ps1

.NOTAS
    Autor: Diogo
    Última atualização: 03/04/2025
#>

﻿$sempres = Import-Csv "D:\Downloads\csfaparasempre.csv"

foreach ($sempre in $sempres) {

$email = $sempre.primaryEmail
$alias1 = $sempre.alias1
$alias2 = $sempre.alias2

gam create aliases $alias1 $alias2 user $email

}