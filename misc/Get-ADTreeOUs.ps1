# Força o encoding UTF-8 com BOM para compatibilidade e limpa o terminal
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8BOM'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Clear-Host

<#
.SINOPSE
  Gera uma visualização hierárquica das OUs do Active Directory no formato "tree".

.DESCRIÇÃO
  Este script consulta todas as Organizational Units (OUs) do Active Directory
  e monta uma representação hierárquica em forma de árvore, semelhante ao comando
  "tree" no Linux. O resultado é exibido no console e salvo em arquivo.

.EXEMPLO
  .\Get-ADTreeOUs.ps1

.NOTAS
  Autor: Diogo
  Criado em: 10/09/2025

  Changelog:
    - 10/09/2025 v1.0 - Criação do script
#>

# Caminho para salvar a lista gerada
$logPath = "D:\Scripts\logs\AD_OU_Tree.txt"

# Função recursiva para montar a hierarquia
function Get-OUTree {
  param (
    [string]$DistinguishedName,
    [int]$Level = 0
  )

  # Indentação com base no nível da OU
  $indent = (" " * ($Level * 2)) + "|-- "

  # Extrai apenas o nome da OU atual
  $ouName = ($DistinguishedName -split ',')[0] -replace '^OU=', ''

  # Escreve no console e no arquivo
  "$indent$ouName" | Tee-Object -FilePath $logPath -Append

  # Busca OUs filhas
  $childOUs = Get-ADOrganizationalUnit -Filter * -SearchBase $DistinguishedName -SearchScope OneLevel -ErrorAction SilentlyContinue

  foreach ($child in $childOUs) {
    Get-OUTree -DistinguishedName $child.DistinguishedName -Level ($Level + 1)
  }
}

# Limpa arquivo de log anterior
"" | Out-File $logPath

Write-Host "Gerando árvore de OUs...`n"

# Pega o domínio raiz
$root = (Get-ADDomain).DistinguishedName

# Inicia recursão pelas OUs no nível raiz
$rootOUs = Get-ADOrganizationalUnit -Filter * -SearchBase $root -SearchScope OneLevel

foreach ($ou in $rootOUs) {
  Get-OUTree -DistinguishedName $ou.DistinguishedName -Level 0
}

Write-Host "`nÁrvore de OUs gerada com sucesso!"
Write-Host "Arquivo salvo em: $logPath"
