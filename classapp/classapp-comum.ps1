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
