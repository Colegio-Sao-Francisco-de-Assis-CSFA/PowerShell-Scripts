param(
    [switch]$Teste,
    [ValidateRange(1,30)][int]$Tentativas = 12,
    [ValidateRange(1,60)][int]$IntervaloSegundos = 10
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'classapp-comum.ps1')
$diretorioLogs = Join-Path $PSScriptRoot 'logs'
$null = New-Item -ItemType Directory -Path $diretorioLogs -Force
$arquivoExecucao = Join-Path $diretorioLogs ('get-' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '-' + [guid]::NewGuid().ToString('N').Substring(0,6) + '.log')
$null = Start-Transcript -Path $arquivoExecucao -ErrorAction Stop
try {
$ambiente = 'producao'
$variavelToken = 'CLASSAPP_TOKEN_PRODUCAO'
if ($Teste) { $ambiente = 'teste'; $variavelToken = 'CLASSAPP_TOKEN_TESTE' }
$pasta = Join-Path $PSScriptRoot 'dados'
$null = New-Item -ItemType Directory -Path $pasta -Force
$destino = Join-Path $pasta "alunos-$ambiente.json"
$headers = @{ Authorization = 'Bearer ' + (Read-DotEnvToken -Nome $variavelToken) }
Write-Host "Ambiente: $ambiente | consulta de alunos; não envia mensagens."
try {
    # Sem filtro: preserva os inativos para que a validação os identifique.
    $resultado = Invoke-RestMethod -Method Get -Uri 'https://api.classapp.com.br/v1/student' -Headers $headers -TimeoutSec 60
}
finally { $headers.Clear() }
if (-not $resultado.bucketFile) { throw 'A API não retornou bucketFile. Base anterior preservada.' }
$url = [uri]$resultado.bucketFile
if ($url.Scheme -ne 'https') { throw 'Link de exportação não usa HTTPS.' }
$conteudoValido = $null
for ($tentativa=1; $tentativa -le $Tentativas; $tentativa++) {
    Write-Host "Baixando a mesma exportação: tentativa $tentativa de $Tentativas..."
    try {
        $resposta = Invoke-WebRequest -Uri $url.AbsoluteUri -UseBasicParsing -TimeoutSec 60 -Headers @{ 'Cache-Control'='no-cache' }
        $conteudo = $resposta.Content
        if ($conteudo -is [byte[]]) { $conteudo = [Text.Encoding]::UTF8.GetString($conteudo) }
        $conteudo = ([string]$conteudo).TrimStart([char]0xFEFF)
        $alunos = @(ConvertFrom-ClassAppAlunosJson -Texto $conteudo)
        $conteudoValido = $conteudo
        break
    }
    catch {
        Write-Host "Exportação indisponível/inválida: $($_.Exception.Message)"
        if ($tentativa -eq $Tentativas) { throw 'Não foi possível atualizar a base. Base anterior preservada. Confira o ClassApp/suporte antes de tentar novamente.' }
        Start-Sleep -Seconds $IntervaloSegundos
    }
}
$temporario = $destino + '.' + [guid]::NewGuid().ToString('N') + '.tmp'
try {
    [IO.File]::WriteAllText($temporario,$conteudoValido,[Text.UTF8Encoding]::new($false))
    if (Test-Path -LiteralPath $destino) {
        $backup = Join-Path $pasta ("alunos-$ambiente-anterior-" + (Get-Date -Format 'yyyyMMdd-HHmmss') + '-' + [guid]::NewGuid().ToString('N').Substring(0,6) + '.json')
        [IO.File]::Replace($temporario,$destino,$backup)
    }
    else { [IO.File]::Move($temporario,$destino) }
}
finally { if (Test-Path -LiteralPath $temporario) { Remove-Item -LiteralPath $temporario -Force } }
Write-Host "Base atualizada: $destino | Cadastros: $($alunos.Count)"

}
catch {
    Write-Host ("ERRO: " + $_.Exception.Message) -ForegroundColor Red
    throw
}
finally {
    $null = Stop-Transcript
    Write-Host "Log da execução: $arquivoExecucao"
}
