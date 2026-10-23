param(
    [string]$Csv,
    [switch]$Enviar,
    [switch]$Producao
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'classapp-comum.ps1')
$ambiente = 'teste'
$variavelToken = 'CLASSAPP_TOKEN_TESTE'
if ($Producao) { $ambiente = 'producao'; $variavelToken = 'CLASSAPP_TOKEN_PRODUCAO' }
$banco = Join-Path $PSScriptRoot "dados/alunos-$ambiente.json"
$comandoGet = '.\get-api-classapp.ps1 -Teste'
if ($Producao) { $comandoGet = '.\get-api-classapp.ps1' }
if (-not (Test-Path -LiteralPath $banco)) { throw "Base não encontrada. Execute $comandoGet e rode o envio novamente." }
try {
    $textoBase = [IO.File]::ReadAllText($banco, [Text.Encoding]::UTF8).TrimStart([char]0xFEFF)
    if (-not $textoBase.TrimStart().StartsWith('[')) { throw 'Formato inválido.' }
    $alunos = @(ConvertFrom-Json -InputObject $textoBase)
    if ($alunos.Count -eq 0 -or $null -eq $alunos[0]) { throw 'Base vazia.' }
    foreach ($a in $alunos) {
        if ([string]::IsNullOrWhiteSpace($a.fullname) -or $a.disabled -isnot [bool]) { throw 'Cadastro inválido.' }
    }
}
catch { throw "Base de alunos inválida. Execute $comandoGet e rode o envio novamente." }

if ([string]::IsNullOrWhiteSpace($Csv)) { $Csv = Read-Host 'Caminho completo do CSV de mensagens' }
$Csv = $Csv.Trim().Trim('"').Trim("'")
if (-not (Test-Path -LiteralPath $Csv -PathType Leaf)) { throw "CSV não encontrado: $Csv" }
$cabecalho = Get-Content -LiteralPath $Csv -Encoding UTF8 -TotalCount 1
$delimitador = ','
if ($cabecalho -match '^\s*"?enviar"?;') { $delimitador = ';' }
elseif ($cabecalho -notmatch '^\s*"?enviar"?,') { throw 'CSV inválido: a primeira coluna deve ser enviar. Consulte INSTRUCOES-CSV.md.' }
$linhas = @(Import-Csv -LiteralPath $Csv -Delimiter $delimitador -Encoding UTF8)
if ($linhas.Count -eq 0) { throw 'CSV sem dados.' }
foreach ($campo in @('enviar','nome','assunto','mensagem')) {
    if ($linhas[0].PSObject.Properties.Name -notcontains $campo) { throw "Coluna obrigatória ausente: $campo" }
}

$indice = @{}
foreach ($a in $alunos) {
    $chave = ConvertTo-NomeNormalizado ([string]$a.fullname)
    if (-not $indice.ContainsKey($chave)) { $indice[$chave] = @() }
    $indice[$chave] += $a
}
$erros = [Collections.Generic.List[string]]::new()
$lote = [Collections.Generic.List[object]]::new()
$vistos = @{}
$numero = 1
foreach ($linha in $linhas) {
    $numero++
    $marcacao = ([string]$linha.enviar).Trim().ToUpperInvariant()
    if ($marcacao -in @('NAO','NÃO','')) { continue }
    if ($marcacao -ne 'SIM') { $erros.Add("Registro ${numero}: enviar deve ser SIM ou NÃO."); continue }
    $nome = ([string]$linha.nome).Trim()
    $chave = ConvertTo-NomeNormalizado $nome
    $encontrados = @()
    if ($indice.ContainsKey($chave)) { $encontrados = @($indice[$chave]) }
    if ($encontrados.Count -eq 0) { $erros.Add("Registro ${numero}: aluno não encontrado: $nome"); continue }
    if ($encontrados.Count -ne 1) { $erros.Add("Registro ${numero}: nome duplicado na base: $nome. Identificação manual necessária."); continue }
    $aluno = $encontrados[0]
    if ($aluno.disabled) { $erros.Add("Registro ${numero}: aluno inativo: $nome"); continue }
    $eid = ([string]$aluno.eid).Trim()
    if (-not $eid) { $erros.Add("Registro ${numero}: aluno sem EID: $nome"); continue }
    if (@($alunos | Where-Object { ([string]$_.eid).Trim() -eq $eid }).Count -ne 1) {
        $erros.Add("Registro ${numero}: EID duplicado na base para $nome"); continue
    }
    try {
        $assunto = Expand-Modelo ([string]$linha.assunto) $linha
        $mensagem = Expand-Modelo ([string]$linha.mensagem) $linha
        if ($assunto -match '\{\{|\}\}' -or $mensagem -match '\{\{|\}\}') { throw 'Variável não resolvida ou malformada.' }
        if ([string]::IsNullOrWhiteSpace($assunto) -or [string]::IsNullOrWhiteSpace($mensagem)) { throw 'Assunto ou mensagem vazio.' }
        if ($assunto -match '#REF!|#VALUE!|#NAME\?' -or $mensagem -match '#REF!|#VALUE!|#NAME\?') { throw 'Erro de fórmula no texto.' }
        $tipo = ([string]$linha.tipo).Trim().ToLowerInvariant()
        if (-not $tipo) { $tipo = 'comunicado' }
        if ($tipo -notin @('comunicado','academico','financeiro','aviso')) { throw 'Tipo inválido.' }
        $responder = ([string]$linha.responder).Trim().ToUpperInvariant()
        if (-not $responder) { $responder = 'SIM' }
        if ($responder -notin @('SIM','NAO','NÃO')) { throw 'responder deve ser SIM ou NÃO.' }
        $html = '<p>' + ([Net.WebUtility]::HtmlEncode($mensagem) -replace '\r\n|\r|\n','<br>') + '</p>'
        $payload = @{ messageData = @{ subject=$assunto; content=$html; type=$tipo; noReply=($responder -ne 'SIM'); recipients=@{eids=@($eid)} } } | ConvertTo-Json -Depth 10 -Compress
        $hash = Get-TextoHash (ConvertTo-Json -InputObject @($ambiente,$eid,$assunto,$mensagem,$tipo,$responder) -Compress)
        if ($vistos.ContainsKey($hash)) { throw 'Mensagem idêntica duplicada no CSV.' }
        $vistos[$hash] = $true
        $lote.Add([pscustomobject]@{ nome=$aluno.fullname; eid=$eid; assunto=$assunto; mensagem=$mensagem; payload=$payload; hash=$hash })
    }
    catch { $erros.Add("Registro ${numero} ($nome): $($_.Exception.Message)") }
}
if ($erros.Count -gt 0) {
    foreach ($erroValidacao in $erros) { Write-Host $erroValidacao -ForegroundColor Red }
    throw "LOTE BLOQUEADO: nenhuma mensagem enviada. Execute $comandoGet para atualizar a base e corrija nomes/duplicidades/EIDs no cadastro ou o CSV antes de tentar novamente."
}
if ($lote.Count -eq 0) { Write-Host 'Nenhuma linha marcada SIM.'; return }
Write-Host "`nAmbiente: $ambiente | Base: $banco | Atualizada em: $((Get-Item -LiteralPath $banco).LastWriteTime)"
foreach ($item in $lote) {
    Write-Host "`nAluno: $($item.nome) | EID: $($item.eid)"
    Write-Host "Assunto: $($item.assunto)"
    Write-Host $item.mensagem
}
Write-Host "`nTotal validado: $($lote.Count)"
if (-not $Enviar) { Write-Host 'PRÉVIA: nenhum envio. Execute novamente com -Enviar para enviar.'; return }

# O histórico impede repetição automática de mensagens iguais e de tentativas inconclusivas.
$pastaLog = Join-Path $PSScriptRoot 'logs'
$null = New-Item -ItemType Directory -Path $pastaLog -Force
$trava = Join-Path $pastaLog "envio-$ambiente.lock"
try { $lock = [IO.File]::Open($trava, [IO.FileMode]::OpenOrCreate, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None) }
catch { throw 'Já existe um envio em execução neste ambiente. Aguarde terminar.' }
$headers = @{}
try {
    $historico = Join-Path $pastaLog "historico-$ambiente.csv"
    $anteriores = @{}
    if (Test-Path -LiteralPath $historico) {
        foreach ($r in Import-Csv -LiteralPath $historico -Delimiter ';' -Encoding UTF8) { $anteriores[[string]$r.hash] = $r }
    }
    foreach ($item in $lote) {
        if ($anteriores.ContainsKey($item.hash)) {
            throw "Já existe tentativa registrada para $($item.nome), assunto '$($item.assunto)'. Nenhuma mensagem deste lote foi enviada. Confira o histórico e marque a linha como NÃO; tentativas inconclusivas exigem conferência no ClassApp."
        }
    }
    $headers.Authorization = 'Bearer ' + (Read-DotEnvToken -Nome $variavelToken)
    foreach ($item in $lote) {
        $registro = [pscustomobject]@{ data=(Get-Date).ToString('o'); ambiente=$ambiente; nome=$item.nome; eid=$item.eid; assunto=$item.assunto; hash=$item.hash; status='TENTATIVA_INICIADA'; broker_message_id=''; detalhe='Conferir antes de reenviar se a execução for interrompida.' }
        $registro | Export-Csv -LiteralPath $historico -Delimiter ';' -Encoding UTF8 -NoTypeInformation -Append
        try {
            $resposta = Invoke-WebRequest -Method Post -Uri 'https://api.classapp.com.br/v1/message' `
                -UseBasicParsing -Headers $headers -ContentType 'application/json; charset=utf-8' `
                -Body ([Text.Encoding]::UTF8.GetBytes($item.payload)) -TimeoutSec 60
            $registro.status = 'HTTP_SUCESSO_CONFERIR_ENTREGA'
            $texto = $resposta.Content
            if ($texto -is [byte[]]) { $texto = [Text.Encoding]::UTF8.GetString($texto) }
            $registro.detalhe = "HTTP $($resposta.StatusCode): $texto"
            try {
                $retorno = ConvertFrom-Json -InputObject ([string]$texto) -ErrorAction Stop
                $registro.broker_message_id = [string]$retorno.broker_message_id
            } catch { } # Corpo vazio ou não JSON não transforma HTTP de sucesso em falha.
            $registro | Export-Csv -LiteralPath $historico -Delimiter ';' -Encoding UTF8 -NoTypeInformation -Append
            Write-Host "Solicitação aceita: $($item.nome) | HTTP $($resposta.StatusCode)"
        }
        catch {
            $registro.status = 'CONFERIR_ANTES_DE_REENVIAR'
            $registro.detalhe = $_.Exception.Message + ' ' + $_.ErrorDetails.Message
            $registro | Export-Csv -LiteralPath $historico -Delimiter ';' -Encoding UTF8 -NoTypeInformation -Append
            throw "Envio interrompido para $($item.nome). Confira o ClassApp e o histórico antes de repetir."
        }
        Start-Sleep -Seconds 1
    }
    Write-Host "`nLote solicitado. Confirme a entrega no ClassApp. Histórico: $historico"
}
finally { $headers.Clear(); $lock.Dispose() }
