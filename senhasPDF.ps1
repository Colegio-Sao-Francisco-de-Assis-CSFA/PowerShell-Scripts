#Antes de rodar esse script, confira se os boletos e o arquivo das senhas já foi gerado.
#Para gerar os boletos, acesse o SIGA pela versão desktop, na aba Financeiro -> Cobrança Registrada -> escolha o lote correto de boletos -> Operações ->
#Gerar/Enviar boleto em PDF -> Apenas gerar PDF -> Formato de geração: matrícula - título

$caminho = "D:\Downloads\boletos dez" #caminho para a pasta do mês

$arquivos = Import-Csv "$caminho\senhas.csv"

if (Test-Path -Path "$caminho\protected") {
Write-Warning "Pasta protected já existe, iniciando script."
}
else {
Write-Warning "Pasta protected não existe, criando antes de iniciar o script."
New-Item -ItemType Directory -Path "$caminho\protected"
}

if (Test-Path -Path "$caminho\financeiro") {
Write-Warning "Pasta financeiro já existe, iniciando script."
}
else {
Write-Warning "Pasta financeiro não existe, criando antes de iniciar o script."
New-Item -ItemType Directory -Path "$caminho\financeiro"
}

foreach ($arquivo in $arquivos) {
$cod = $arquivo.cod
$nome = $arquivo.nome
$senha = $arquivo.senha

if (Test-Path -Path "$caminho\$cod.pdf" -PathType Leaf) {
Copy-Item "$caminho\$cod.pdf" -Destination "$caminho\financeiro\$nome - $cod.pdf"
Write-Warning "$cod.pdf copiado para a pasta financeiro e renomeado para $nome - $cod.pdf."
pdftk "$caminho\$cod.pdf" output "$caminho\protected\$cod.pdf" user_pw $senha 
Write-Warning "$cod.pdf protegido e copiado para a pasta protected."
}
else {
Write-Warning "Arquivo $cod.pdf não existe."
}

}

Write-Warning "Script finalizado."