# Funções compartilhadas. Carregue este arquivo pelos scripts principais.
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

function ConvertTo-NomeNormalizado {
    param([string]$Nome)
    $decomposto = $Nome.Normalize([Text.NormalizationForm]::FormD)
    $semAcentos = [regex]::Replace($decomposto, '\p{M}', '')
    return ([regex]::Replace($semAcentos.Trim(), '\s+', ' ')).ToUpperInvariant()
}

function ConvertFrom-ClassAppAlunosJson {
    param([string]$Texto)
    $textoLimpo = $Texto.TrimStart([char]0xFEFF).Trim()
    if (-not $textoLimpo) { throw 'Arquivo sem conteúdo.' }
    if (-not $textoLimpo.StartsWith('[')) { throw 'A raiz do JSON deve ser uma lista de alunos.' }
    $convertido = ConvertFrom-Json -InputObject $textoLimpo -ErrorAction Stop
    $quantidade = 0
    # Iteração explícita evita a diferença de enumeração do ConvertFrom-Json no PS 5.1 e 7.
    foreach ($cadastro in $convertido) {
        $quantidade++
        if ($null -eq $cadastro) { throw "Cadastro ${quantidade}: registro nulo." }
        $nome = $cadastro.PSObject.Properties['fullname']
        $eid = $cadastro.PSObject.Properties['eid']
        $status = $cadastro.PSObject.Properties['disabled']
        if ($null -eq $nome -or $nome.Value -isnot [string] -or [string]::IsNullOrWhiteSpace($nome.Value)) {
            throw "Cadastro ${quantidade}: fullname ausente ou inválido."
        }
        if ($null -eq $eid) { throw "Cadastro ${quantidade} ($($nome.Value)): campo eid ausente." }
        if ($null -eq $status -or $status.Value -isnot [bool]) {
            $tipo = 'nulo/ausente'
            if ($null -ne $status -and $null -ne $status.Value) { $tipo = $status.Value.GetType().FullName }
            throw "Cadastro ${quantidade} ($($nome.Value)): disabled precisa ser booleano; recebido: $tipo."
        }
        # EID vazio é permitido na exportação; o lote bloqueia apenas destinatários sem EID.
        Write-Output $cadastro
    }
    if ($quantidade -eq 0) { throw 'Lista de alunos vazia.' }
}

function Expand-Modelo {
    param([string]$Modelo, [object]$Linha)
    return [regex]::Replace($Modelo, '\{\{\s*([A-Za-z_][A-Za-z0-9_]*)\s*\}\}', [Text.RegularExpressions.MatchEvaluator]{
        param($ocorrencia)
        $coluna = $ocorrencia.Groups[1].Value
        $propriedade = $Linha.PSObject.Properties[$coluna]
        if ($null -eq $propriedade -or [string]::IsNullOrWhiteSpace([string]$propriedade.Value)) {
            throw "Variável sem coluna ou valor: $coluna"
        }
        return [string]$propriedade.Value
    })
}

function Get-TextoHash {
    param([string]$Texto)
    $sha = [Security.Cryptography.SHA256]::Create()
    try { return ([BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($Texto)))).Replace('-','').ToLowerInvariant() }
    finally { $sha.Dispose() }
}
