param(
    [string]$Csv = (Join-Path $PSScriptRoot 'mensagens-teste-eureka.csv'),
    [switch]$Enviar
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

if (-not (Test-Path -LiteralPath $Csv)) { throw "CSV não encontrado: $Csv" }
$primeiraLinha = Get-Content -LiteralPath $Csv -Encoding UTF8 -TotalCount 1
if ($primeiraLinha -match '^"?Enviar"?;') { $separador = ';' }
elseif ($primeiraLinha -match '^"?Enviar"?,') { $separador = ',' }
else { throw 'Exporte somente A5:H28 da aba Mensagens de teste: a primeira linha deve começar com Enviar, sem título acima.' }

$linhas = @(Import-Csv -LiteralPath $Csv -Delimiter $separador -Encoding UTF8)
$obrigatorias = @('Enviar', 'Aluno da mensagem', 'EID de teste', 'Cadastro destinatário', 'Assunto', 'Mensagem para revisão', 'HTML para API')
if ($linhas.Count -eq 0) { throw 'CSV sem dados.' }
foreach ($coluna in $obrigatorias) {
    if ($linhas[0].PSObject.Properties.Name -notcontains $coluna) { throw "Coluna ausente: $coluna" }
}
$selecionadas = @($linhas | Where-Object { ([string]$_.Enviar).Trim() -ieq 'SIM' })
if ($selecionadas.Count -eq 0) { Write-Host 'Nenhuma linha marcada SIM.'; return }

# Valida todas as linhas antes de começar. Restrito aos dois EIDs deste teste.
foreach ($linha in $selecionadas) {
    $eid = ([string]$linha.'EID de teste').Trim()
    if ($eid -notin @('1010', 'TESTE-ANDRE')) { throw "EID fora do teste: $eid" }
    foreach ($campo in @('Aluno da mensagem', 'Assunto', 'Mensagem para revisão', 'HTML para API')) {
        if ([string]::IsNullOrWhiteSpace($linha.$campo)) { throw "Campo vazio: $campo" }
    }
    if ($linha.'HTML para API' -match '#REF!|#VALUE!|#NAME\?|\{\{') { throw 'Mensagem com erro de fórmula ou variável não preenchida.' }
    Write-Host "`nAluno: $($linha.'Aluno da mensagem')"
    Write-Host "Destino: $($linha.'Cadastro destinatário') | EID: $eid"
    Write-Host "Assunto: $($linha.Assunto)"
    Write-Host $linha.'Mensagem para revisão'
}
Write-Host "`nTotal selecionado: $($selecionadas.Count) mensagem(ns)."
if (-not $Enviar) {
    Write-Host 'PRÉVIA: nenhuma mensagem enviada. Use -Enviar para executar os envios.'
    return
}

$cabecalhos = @{ Authorization = 'Bearer ' + (Read-DotEnvToken -Nome 'CLASSAPP_TOKEN_TESTE') }
Write-Host 'Ambiente: TESTE | somente EIDs 1010 e TESTE-ANDRE.'
$pastaCsv = Split-Path -Parent (Resolve-Path -LiteralPath $Csv).Path
$arquivoLog = Join-Path $pastaCsv ('resultado-classapp-' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '-' + [guid]::NewGuid().ToString('N').Substring(0, 6) + '.csv')

try {
    foreach ($linha in $selecionadas) {
        $eid = ([string]$linha.'EID de teste').Trim()
        $registro = [pscustomobject]@{
            data              = (Get-Date).ToString('o')
            aluno             = $linha.'Aluno da mensagem'
            eid               = $eid
            assunto           = $linha.Assunto
            status            = 'EM_ANDAMENTO'
            broker_message_id = ''
            detalhe           = 'Tentativa iniciada; não reenviar sem conferir o ClassApp.'
        }
        # Registra antes da chamada para permitir conferência após interrupções.
        $registro | Export-Csv -LiteralPath $arquivoLog -Delimiter ';' -NoTypeInformation -Encoding UTF8 -Append
        $corpo = @{
            messageData = @{
                subject    = $linha.Assunto
                content    = $linha.'HTML para API'
                type       = 'academico'
                noReply    = $false
                recipients = @{ eids = @($eid) }
            }
        } | ConvertTo-Json -Depth 10
        try {
            $retorno = Invoke-RestMethod -Method Post `
                -Uri 'https://api.classapp.com.br/v1/message' `
                -Headers $cabecalhos `
                -ContentType 'application/json; charset=utf-8' `
                -Body ([Text.Encoding]::UTF8.GetBytes($corpo)) `
                -TimeoutSec 60 -ErrorAction Stop
            $registro.broker_message_id = [string]$retorno.broker_message_id
            $registro.status = 'RESPOSTA_RECEBIDA'
            $registro.detalhe = ($retorno | ConvertTo-Json -Compress -Depth 10)
            if ($registro.broker_message_id) { $registro.status = 'ACEITA_PARA_PROCESSAMENTO' }
            $registro | Export-Csv -LiteralPath $arquivoLog -Delimiter ';' -NoTypeInformation -Encoding UTF8 -Append
            Write-Host "Solicitação processada: $($registro.aluno) | broker: $($registro.broker_message_id)"
            if (-not $registro.broker_message_id) { Write-Host 'Resposta sem broker_message_id registrada no log; continuando. Confirme o recebimento no ClassApp.' }
        }
        catch {
            $registro.status = 'CONFERIR_ANTES_DE_REENVIAR'
            $registro.detalhe = $_.Exception.Message + ' ' + $_.ErrorDetails.Message
            $registro | Export-Csv -LiteralPath $arquivoLog -Delimiter ';' -NoTypeInformation -Encoding UTF8 -Append
            throw "Execução interrompida. Confira o ClassApp antes de repetir. Detalhe: $($registro.detalhe)"
        }
        Start-Sleep -Seconds 1
    }
}
finally {
    $cabecalhos.Clear()
    Write-Host "`nRegistro da execução: $arquivoLog"
}
Write-Host 'Envios solicitados. Confirme o recebimento no ClassApp. Executar novamente envia novamente.'
