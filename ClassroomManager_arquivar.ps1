# Atualizar os nomes e arquivar as turmas do Google Classroom
$turmas = Import-Csv "D:\Downloads\classroom_manager.csv"
$ano = Read-Host "Que ano foi finalizado?"

foreach ($turma in $turmas) {

$id = $turma.id
$nome = $turma.name
$alias = $turma.Aliases
$novonome = "$ano | $nome"

gam update course $id name $novonome `
status ARCHIVED

Write-Warning "Turma $nome arquivada e nome alterado para $novonome."

gam course $id delete alias $alias

Write-Warning "alias $alias deletado."

gam course $id sync teachers group "owners@colsaofrancisco.com.br"

}

Write-Warning "Script finalizado."