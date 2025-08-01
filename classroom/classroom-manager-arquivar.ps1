<#
.SINOPSE
Arquiva turmas do Google Classroom e atualiza seus nomes com o ano finalizado.

.DESCRIÇÃO
Este script lê um arquivo CSV com as turmas e realiza três ações principais:
- Renomeia a turma incluindo o ano de finalização no nome
- Arquiva a turma
- Remove o alias associado
Também sincroniza o grupo de professores responsáveis com o grupo 'owners'.

.EXEMPLO
.\classroom-manager-arquivar.ps1

.NOTAS
Autor: Diogo
Última atualização: 08/04/2025
#>

# Força o encoding UTF-8 com BOM para compatibilidade e limpa o terminal
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8BOM'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Clear-Host

# Importa os dados das turmas a partir de um CSV
$turmas = Import-Csv "D:\Downloads\classroom_manager.csv"

# Solicita o ano de finalização das turmas
$ano = Read-Host "Que ano foi finalizado?"

# Itera sobre cada turma
foreach ($turma in $turmas) {

  $id = $turma.id
  $nome = $turma.name
  $alias = $turma.Aliases
  $novonome = "$ano | $nome"

  # Atualiza o nome e arquiva a turma
  gam update course $id name $novonome `
    status ARCHIVED

  Write-Warning "Turma $nome arquivada e nome alterado para $novonome."

  # Remove o alias antigo
  gam course $id delete alias $alias

  Write-Warning "Alias $alias deletado."

  # Sincroniza os professores responsáveis com o grupo 'owners'
  gam course $id sync teachers group "owners@colsaofrancisco.com.br"
}

Write-Warning "Script finalizado."
