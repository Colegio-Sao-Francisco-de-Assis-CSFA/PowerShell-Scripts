# Força o encoding UTF-8 com BOM para compatibilidade e limpa o terminal
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8BOM'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Clear-Host

<#
.SINOPSE
  Processa fotos de alunos com base em um arquivo CSV, copiando e renomeando para múltiplos destinos.

.DESCRIÇÃO
  Este script realiza o processamento de fotos de alunos utilizando um arquivo CSV como base.

  Fluxo do script:
    - Solicita a pasta de origem das fotos
    - Solicita o arquivo CSV contendo os dados dos alunos
    - Solicita a extensão dos arquivos (ex: .jpg)
    - Cria automaticamente as pastas de destino:
        GDS, AD, gsuite, coordenacao, classapp, SIGA
    - Copia cada foto para as pastas, renomeando conforme os dados do CSV
    - Move os arquivos originais para a pasta "originais"
    - Gera um log detalhado do processamento

  Requisitos:
    - Os arquivos de imagem devem ter como nome o campo NUMERO do aluno (sem extensão)
    - O CSV deve estar em UTF-8 e conter as colunas:
        NUMERO, nome, email
    - O separador do CSV deve ser vírgula (,)

.EXEMPLO
  .\processarFotos_Alunos.ps1

.NOTAS
  Autor: Diogo
  Criado em: 03/04/2025
  Atualizado em: 26/03/2026

  Changelog:
    - 26/03/2026 v2.0 - Padronização pt-BR, correção de encoding, melhorias de performance e estrutura
#>

# Solicita entradas do usuário
$origem = Read-Host "Informe o caminho da pasta onde estão as fotos (ex: C:\Scripts\fotos)"
$caminhoCSV = Read-Host "Informe o caminho completo do arquivo CSV"
$extensao = Read-Host "Informe a extensão dos arquivos (ex: .jpg)"

# Caminho do log (padrão do projeto)
$logPath = "C:\Users\dnunes\Downloads\log_fotos_alunos.txt"

# Cria pasta "originais"
$caminhoOriginais = Join-Path $origem "originais"
if (-not (Test-Path $caminhoOriginais)) {
  New-Item -ItemType Directory -Path $caminhoOriginais | Out-Null
}

# Inicializa o log
"Log de processamento - $(Get-Date)" | Out-File -FilePath $logPath
"" | Out-File -FilePath $logPath -Append

# Importa CSV
$alunos = Import-Csv -Path $caminhoCSV -Delimiter ","

# Cria um índice (hash table) para otimizar busca
$indiceAlunos = @{}
foreach ($aluno in $alunos) {
  $indiceAlunos[$aluno.NUMERO] = $aluno
}

# Pastas de destino
$pastasDestino = @("GDS", "AD", "gsuite", "coordenacao", "classapp", "SIGA")

foreach ($pasta in $pastasDestino) {
  $caminhoPasta = Join-Path $origem $pasta
  if (-not (Test-Path $caminhoPasta)) {
    New-Item -ItemType Directory -Path $caminhoPasta | Out-Null
  }
}

# Processamento dos arquivos
Get-ChildItem -Path $origem -Filter "*$extensao" -File | ForEach-Object {

  $arquivo = $_
  $nomeArquivo = [System.IO.Path]::GetFileNameWithoutExtension($arquivo.Name)

  if ($indiceAlunos.ContainsKey($nomeArquivo)) {

    $aluno = $indiceAlunos[$nomeArquivo]

    # Definição dos destinos
    $destinos = @{
      "GDS"         = "$($aluno.NUMERO)$extensao"
      "AD"          = "$($aluno.email)$extensao"
      "gsuite"      = "$($aluno.email)$extensao"
      "coordenacao" = "$($aluno.nome)$extensao"
      "classapp"    = "$($aluno.nome)$extensao"
      "SIGA"        = "$($aluno.NUMERO)$extensao"
    }

    foreach ($pasta in $destinos.Keys) {
      $destinoFinal = Join-Path (Join-Path $origem $pasta) $destinos[$pasta]
      Copy-Item -Path $arquivo.FullName -Destination $destinoFinal -Force
    }

    # Move original
    Move-Item -Path $arquivo.FullName -Destination $caminhoOriginais -Force

    # Log sucesso
    $msg = "[OK] $($arquivo.Name) processado para $($aluno.nome)"
    Write-Host $msg -ForegroundColor Green
    $msg | Out-File -FilePath $logPath -Append
  }
  else {
    # Log erro
    $msg = "[ERRO] $($arquivo.Name) - código $nomeArquivo não encontrado no CSV"
    Write-Host $msg -ForegroundColor Red
    $msg | Out-File -FilePath $logPath -Append
  }

}

Write-Host "`nProcessamento concluído! Log em: $logPath" -ForegroundColor Cyan
