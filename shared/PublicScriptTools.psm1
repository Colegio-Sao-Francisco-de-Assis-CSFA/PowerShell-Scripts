# Módulo compartilhado para centralizar funções básicas usadas pelos scripts públicos.
# A ideia aqui é evitar repetição e deixar cada script focado na regra de negócio.

Set-StrictMode -Version Latest

function Get-ProjectRoot {
  <#
  .SINOPSE
    Retorna a raiz do projeto com base na pasta do módulo.
  #>

  return (Split-Path -Parent $PSScriptRoot)
}

function Import-EnvConfiguration {
  <#
  .SINOPSE
    Lê o arquivo .env da raiz do projeto e devolve os valores em uma hashtable.

  .DESCRIÇÃO
    Esta função faz uma leitura simples do arquivo .env no formato CHAVE=VALOR.
    Linhas vazias e linhas iniciadas com # são ignoradas.
  #>

  param(
    [string]$CaminhoEnv = (Join-Path (Get-ProjectRoot) ".env")
  )

  $configuracoes = @{}

  if (-not (Test-Path -LiteralPath $CaminhoEnv)) {
    return $configuracoes
  }

  foreach ($linhaBruta in (Get-Content -LiteralPath $CaminhoEnv -ErrorAction Stop)) {
    $linha = $linhaBruta.Trim()

    if ([string]::IsNullOrWhiteSpace($linha)) {
      continue
    }

    if ($linha.StartsWith("#")) {
      continue
    }

    $partes = $linha -split "=", 2
    if ($partes.Count -ne 2) {
      continue
    }

    $chave = $partes[0].Trim()
    $valor = $partes[1].Trim()

    if (-not [string]::IsNullOrWhiteSpace($chave)) {
      $configuracoes[$chave] = $valor
    }
  }

  return $configuracoes
}

function Get-ConfigValue {
  <#
  .SINOPSE
    Retorna o valor de uma chave do .env com suporte a valor padrão.
  #>

  param(
    [Parameter(Mandatory)]
    [hashtable]$Configuracoes,

    [Parameter(Mandatory)]
    [string]$Chave,

    [string]$ValorPadrao = ""
  )

  if ($Configuracoes.ContainsKey($Chave) -and -not [string]::IsNullOrWhiteSpace($Configuracoes[$Chave])) {
    return $Configuracoes[$Chave]
  }

  return $ValorPadrao
}

function Initialize-LogDirectory {
  <#
  .SINOPSE
    Cria e retorna a pasta de logs de um script.

  .DESCRIÇÃO
    A pasta base é lida do .env pela chave LOGS_DIR.
    Dentro dela, cada script ganha sua própria subpasta para facilitar organização.
  #>

  param(
    [Parameter(Mandatory)]
    [hashtable]$Configuracoes,

    [Parameter(Mandatory)]
    [string]$NomeScript
  )

  $baseLogs = Get-ConfigValue -Configuracoes $Configuracoes -Chave "LOGS_DIR"

  if ([string]::IsNullOrWhiteSpace($baseLogs)) {
    throw "A chave LOGS_DIR não foi definida no arquivo .env."
  }

  $diretorioScript = Join-Path $baseLogs $NomeScript

  if (-not (Test-Path -LiteralPath $diretorioScript)) {
    New-Item -ItemType Directory -Path $diretorioScript -Force | Out-Null
  }

  return $diretorioScript
}

function Test-CommandAvailable {
  <#
  .SINOPSE
    Garante que um comando externo esteja disponível antes da execução.
  #>

  param(
    [Parameter(Mandatory)]
    [string]$NomeComando
  )

  if (-not (Get-Command $NomeComando -ErrorAction SilentlyContinue)) {
    throw "O comando '$NomeComando' não foi encontrado. Verifique o .env e o PATH do sistema."
  }
}

function Read-FilePath {
  <#
  .SINOPSE
    Solicita e valida o caminho de um arquivo.
  #>

  param(
    [Parameter(Mandatory)]
    [string]$Mensagem,

    [string]$ValorAtual = "",

    [string[]]$ExtensoesPermitidas = @()
  )

  while ($true) {
    $caminho = if (-not [string]::IsNullOrWhiteSpace($ValorAtual)) {
      $ValorAtual
    }
    else {
      Read-Host $Mensagem
    }

    if (-not (Test-Path -LiteralPath $caminho)) {
      Write-Host "Arquivo não encontrado: $caminho" -ForegroundColor Yellow
      $ValorAtual = ""
      continue
    }

    $item = Get-Item -LiteralPath $caminho
    if ($item.PSIsContainer) {
      Write-Host "O caminho informado é uma pasta, mas o script esperava um arquivo." -ForegroundColor Yellow
      $ValorAtual = ""
      continue
    }

    if ($ExtensoesPermitidas.Count -gt 0) {
      $extensao = [System.IO.Path]::GetExtension($item.FullName)
      if ($ExtensoesPermitidas -notcontains $extensao) {
        Write-Host "Extensão inválida. Permitidas: $($ExtensoesPermitidas -join ', ')." -ForegroundColor Yellow
        $ValorAtual = ""
        continue
      }
    }

    return $item.FullName
  }
}

function Import-ValidatedCsv {
  <#
  .SINOPSE
    Importa um CSV e valida se ele contém as colunas obrigatórias.
  #>

  param(
    [Parameter(Mandatory)]
    [string]$CaminhoCsv,

    [Parameter(Mandatory)]
    [string[]]$ColunasObrigatorias
  )

  $dados = Import-Csv -Path $CaminhoCsv

  if (-not $dados) {
    throw "O CSV está vazio: $CaminhoCsv"
  }

  $colunasDisponiveis = @($dados[0].PSObject.Properties.Name)
  $colunasAusentes = @()

  foreach ($coluna in $ColunasObrigatorias) {
    if ($colunasDisponiveis -notcontains $coluna) {
      $colunasAusentes += $coluna
    }
  }

  if ($colunasAusentes.Count -gt 0) {
    throw "O CSV não contém as colunas obrigatórias: $($colunasAusentes -join ', ')"
  }

  return $dados
}

function Confirm-Action {
  <#
  .SINOPSE
    Exige confirmação explícita antes de continuar.
  #>

  param(
    [Parameter(Mandatory)]
    [string]$Mensagem
  )

  $confirmacao = Read-Host "$Mensagem Digite SIM para continuar"
  return ($confirmacao -eq "SIM")
}

function Write-LogMessage {
  <#
  .SINOPSE
    Escreve uma mensagem padronizada no terminal e, opcionalmente, em um arquivo de log.
  #>

  param(
    [Parameter(Mandatory)]
    [string]$Mensagem,

    [ValidateSet("INFO", "SUCESSO", "AVISO", "ERRO")]
    [string]$Nivel = "INFO",

    [string]$ArquivoLog = ""
  )

  $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
  $linha = "[$timestamp] [$Nivel] $Mensagem"

  if (-not [string]::IsNullOrWhiteSpace($ArquivoLog)) {
    Add-Content -Path $ArquivoLog -Value $linha
  }

  $cor = switch ($Nivel) {
    "SUCESSO" { "Green" }
    "AVISO" { "Yellow" }
    "ERRO" { "Red" }
    default { "White" }
  }

  Write-Host $Mensagem -ForegroundColor $cor
}

function New-SecurePassword {
  <#
  .SINOPSE
    Gera uma senha aleatória segura para uso temporário.
  #>

  param(
    [int]$Length = 12,
    [int]$MinSpecial = 2
  )

  $lower = "abcdefghijkmnopqrstuvwxyz"
  $upper = "ABCDEFGHJKLMNPQRSTUVWXYZ"
  $digits = "23456789"
  $special = "!@#$%*-_+?"
  $all = ($lower + $upper + $digits + $special).ToCharArray()

  $chars = New-Object System.Collections.Generic.List[char]
  $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()

  function Get-RandomChar([char[]]$set) {
    $bytes = New-Object byte[] 4
    $rng.GetBytes($bytes)
    $index = [BitConverter]::ToUInt32($bytes, 0) % $set.Length
    return $set[$index]
  }

  for ($i = 0; $i -lt $MinSpecial; $i++) {
    $chars.Add((Get-RandomChar($special.ToCharArray())))
  }

  while ($chars.Count -lt $Length) {
    $chars.Add((Get-RandomChar($all)))
  }

  for ($i = $chars.Count - 1; $i -gt 0; $i--) {
    $bytes = New-Object byte[] 4
    $rng.GetBytes($bytes)
    $j = [BitConverter]::ToUInt32($bytes, 0) % ($i + 1)

    $tmp = $chars[$i]
    $chars[$i] = $chars[$j]
    $chars[$j] = $tmp
  }

  $rng.Dispose()
  return (-join $chars)
}

Export-ModuleMember -Function @(
  "Confirm-Action",
  "Get-ConfigValue",
  "Get-ProjectRoot",
  "Import-EnvConfiguration",
  "Import-ValidatedCsv",
  "Initialize-LogDirectory",
  "New-SecurePassword",
  "Read-FilePath",
  "Test-CommandAvailable",
  "Write-LogMessage"
)