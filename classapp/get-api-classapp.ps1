param(
  [switch]$Todos,
  [ValidateRange(1, 30)][int]$Tentativas = 12,
  [ValidateRange(1, 60)][int]$IntervaloSegundos = 10,
  [string]$Saida = (Join-Path $PSScriptRoot ('alunos-producao-' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '-' + [guid]::NewGuid().ToString('N').Substring(0, 6) + '.json'))
)
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

function Read-DotEnvToken {
  param([string]$Nome)
  $arquivo = Join-Path $PSScriptRoot '.env'
  if (-not (Test-Path -LiteralPath $arquivo)) { throw "Arquivo .env não encontrado: $arquivo" }
  $dados = @{}
  foreach ($linha in Get-Content -LiteralPath $arquivo -Encoding UTF8) {
    $texto = $linha.Trim()
    if (-not $texto -or $texto.StartsWith('#')) { continue }
    $partes = $texto -split '=', 2
    if ($partes.Count -ne 2) { throw 'Linha inválida no .env. Use NOME=valor.' }
    $chave = $partes[0].Trim()
    if ($chave -notmatch '^[A-Za-z_][A-Za-z0-9_]*$') { throw 'Nome de variável inválido no .env.' }
    if ($dados.ContainsKey($chave)) { throw "Variável duplicada no .env: $chave" }
    $valor = $partes[1].Trim()
    if ($valor.Length -ge 2) {
      if (($valor.StartsWith('"') -and $valor.EndsWith('"')) -or
        ($valor.StartsWith("'") -and $valor.EndsWith("'"))) {
        $valor = $valor.Substring(1, $valor.Length - 2)
      }
    }
    $dados[$chave] = $valor
  }
  if (-not $dados.ContainsKey($Nome) -or [string]::IsNullOrWhiteSpace($dados[$Nome])) {
    throw "Configure $Nome no .env. Não será usado outro token como alternativa."
  }
  return $dados[$Nome]
}

$cabecalhos = @{ Authorization = 'Bearer ' + (Read-DotEnvToken -Nome 'CLASSAPP_TOKEN_PRODUCAO') }
$uri = 'https://api.classapp.com.br/v1/student'
if (-not $Todos) { $uri += '?disabled=false' }
Write-Host 'Ambiente: PRODUÇÃO | consulta de alunos (sem envio de mensagens).'
try {
  # Gera uma única exportação; tentativas seguintes consultam o MESMO arquivo.
  $resultado = Invoke-RestMethod -Method Get -Uri $uri -Headers $cabecalhos -TimeoutSec 60
}
finally { $cabecalhos.Clear() }
if (-not $resultado.bucketFile) { throw 'A API não retornou bucketFile.' }
$urlArquivo = [uri]$resultado.bucketFile
if ($urlArquivo.Scheme -ne 'https') { throw 'O link da exportação não usa HTTPS.' }

for ($tentativa = 1; $tentativa -le $Tentativas; $tentativa++) {
  Write-Host "Consultando o arquivo: tentativa $tentativa de $Tentativas..."
  try {
    # Não encaminha o token da API para o endereço do arquivo.
    $resposta = Invoke-WebRequest -Uri $urlArquivo.AbsoluteUri -UseBasicParsing `
      -Headers @{ 'Cache-Control' = 'no-cache' } -TimeoutSec 60
    $conteudo = $resposta.Content
    if ($conteudo -is [byte[]]) { $conteudo = [Text.Encoding]::UTF8.GetString($conteudo) }
    $conteudo = [string]$conteudo
    $conteudo = $conteudo.TrimStart([char]0xFEFF)
    if ([string]::IsNullOrWhiteSpace($conteudo)) { throw 'Arquivo ainda sem conteúdo.' }
    $null = ConvertFrom-Json -InputObject $conteudo -ErrorAction Stop
    if (-not $conteudo.TrimStart().StartsWith('[')) { throw 'JSON com formato diferente da lista de alunos esperada.' }
    $alunos = @(ConvertFrom-Json -InputObject $conteudo)
    if ($alunos.Count -eq 1 -and $null -eq $alunos[0]) { $alunos = @() }
    $destino = [IO.Path]::GetFullPath($Saida)
    $pasta = Split-Path -Parent $destino
    if (-not (Test-Path -LiteralPath $pasta)) { $null = New-Item -ItemType Directory -Path $pasta -Force }
    if (Test-Path -LiteralPath $destino) { throw "O arquivo já existe: $destino. Escolha outro caminho com -Saida." }
    [IO.File]::WriteAllText($destino, $conteudo, [Text.UTF8Encoding]::new($false))
    Write-Host "`nArquivo salvo: $destino"
    Write-Host "Alunos retornados: $($alunos.Count)"
    $alunos | Select-Object fullname, eid, disabled | Format-Table -AutoSize
    return
  }
  catch {
    if (Test-Path -LiteralPath $Saida) { throw }
    Write-Host "Arquivo ainda indisponível ou inválido: $($_.Exception.Message)"
    if ($tentativa -eq $Tentativas) {
      throw 'Exportação não disponível após as tentativas. Confira o e-mail do ClassApp ou procure o suporte; não houve nova solicitação de exportação.'
    }
    Start-Sleep -Seconds $IntervaloSegundos
  }
}
