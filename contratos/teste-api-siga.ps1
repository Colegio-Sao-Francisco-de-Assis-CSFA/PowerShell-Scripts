#siga OT8sJ9RW2OLSbMjzkqvfCT87FeIhS7
#clicksign fd44f104-e153-490c-a746-730f9698efab
#contrato clicksign cacdf152-bf6e-4ab8-9836-af9975c32a60
#clicksign folder id e08f9c1b-a3f3-47e7-af5e-72395e1826f1

param()

# ============================================================
# ENCODING
# ============================================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8


# ============================================================
# CONFIGURAÇÃO
# ============================================================

$alunoId = 5004
$periodo = "2027"

# ------------------------------------------------------------
# Tokens
# ------------------------------------------------------------

$sigaToken = "OT8sJ9RW2OLSbMjzkqvfCT87FeIhS7"
$clicksignToken = "fd44f104-e153-490c-a746-730f9698efab"
$folderId = "e08f9c1b-a3f3-47e7-af5e-72395e1826f1"


# ------------------------------------------------------------
# SIGA
# ------------------------------------------------------------

$sigaBaseUrl = "https://siga03.activesoft.com.br/api/v0"

$sigaHeaders = @{
  Authorization = "Bearer $sigaToken"
}


# ------------------------------------------------------------
# Clicksign
# ------------------------------------------------------------

$clicksignBaseUrl = "https://app.clicksign.com/api/v3"

$clicksignHeaders = @{
  Authorization  = $clicksignToken
  Accept         = "application/vnd.api+json"
  "Content-Type" = "application/vnd.api+json"
}


# ------------------------------------------------------------
# Modelo Clicksign
# ------------------------------------------------------------

$templateKey = "cacdf152-bf6e-4ab8-9836-af9975c32a60"


# ------------------------------------------------------------
# Diretora
# ------------------------------------------------------------

$diretoraNome = "MARIA EVANI RODRIGUES COSTA"
$diretoraEmail = "evani@colsaofrancisco.com.br"
$diretoraCpf = "163.746.428-21"
$diretoraNascimento = "1945-08-06"


# ------------------------------------------------------------
# Prazo para assinatura
# ------------------------------------------------------------

$prazoAssinaturaDias = 7


# ------------------------------------------------------------
# Valores por série
#
# Adicionar outras séries aqui conforme formos definindo.
#
# IMPORTANTE:
# descontoPadrao é o desconto de pontualidade/base que não
# aparece na API de descontos do SIGA.
# ------------------------------------------------------------

$valoresPorSerie = @{
  "1º ano" = @{
    anuidade       = 20144.75
    descontoPadrao = 25
  }

  "4º ano" = @{
    anuidade       = 20144.75
    descontoPadrao = 17
  }

  "6º ano" = @{
    anuidade       = 22991.60
    descontoPadrao = 10
  }
}


# ------------------------------------------------------------
# SEGURANÇA
#
# false = consulta tudo e mostra a conferência, mas NÃO envia
# true  = efetivamente cria e envia na Clicksign
#
# Rode primeiro como false para a aluna 4792.
# ------------------------------------------------------------

$confirmarEnvio = $true


# ============================================================
# FUNÇÕES AUXILIARES
# ============================================================

function Repair-SigaEncoding {
  param(
    [AllowNull()]
    [string]$Value
  )

  if ([string]::IsNullOrEmpty($Value)) {
    return $Value
  }

  $padroesQuebrados = @(
    "Âº",
    "Âª",
    "Â ",
    "Ã§",
    "Ã£",
    "Ã¡",
    "Ãà",
    "Ãâ",
    "Ãã",
    "Ãé",
    "Ãê",
    "Ãí",
    "Ãó",
    "Ãô",
    "Ãõ",
    "Ãú",
    "ÃÇ",
    "ÃÁ",
    "ÃÉ",
    "ÃÍ",
    "ÃÓ",
    "ÃÚ",
    "â€",
    "â€™",
    "â€œ",
    "â€"
  )

  $pareceQuebrado = $false

  foreach ($padrao in $padroesQuebrados) {
    if ($Value.Contains($padrao)) {
      $pareceQuebrado = $true
      break
    }
  }

  if (-not $pareceQuebrado) {
    return $Value
  }

  try {
    $windows1252 = [System.Text.Encoding]::GetEncoding(1252)
    $utf8 = [System.Text.Encoding]::UTF8

    $bytes = $windows1252.GetBytes($Value)

    return $utf8.GetString($bytes)
  }
  catch {
    return $Value
  }
}


function Remove-NonDigits {
  param(
    [AllowNull()]
    [string]$Value
  )

  if ([string]::IsNullOrWhiteSpace($Value)) {
    return ""
  }

  return ($Value -replace "\D", "")
}


function Convert-PhoneToClicksign {
  param(
    [Parameter(Mandatory)]
    [string]$Phone
  )

  $digits = Remove-NonDigits $Phone

  if ([string]::IsNullOrWhiteSpace($digits)) {
    return ""
  }

  # Se vier com DDI 55, remover.
  if ($digits.StartsWith("55") -and $digits.Length -ge 12) {
    $digits = $digits.Substring(2)
  }

  # Clicksign espera DDD + telefone.
  if ($digits.Length -eq 10 -or $digits.Length -eq 11) {
    return $digits
  }

  return ""
}


function Convert-DateToContract {
  param(
    [AllowNull()]
    [string]$Date
  )

  if ([string]::IsNullOrWhiteSpace($Date)) {
    return ""
  }

  return ([DateTime]::Parse($Date)).ToString("dd/MM/yyyy")
}


function Convert-DateToIsoDate {
  param(
    [AllowNull()]
    [string]$Date
  )

  if ([string]::IsNullOrWhiteSpace($Date)) {
    return ""
  }

  return ([DateTime]::Parse($Date)).ToString("yyyy-MM-dd")
}


function Format-Brl {
  param(
    [Parameter(Mandatory)]
    [decimal]$Value
  )

  $culture = [System.Globalization.CultureInfo]::GetCultureInfo("pt-BR")

  return $Value.ToString("C2", $culture)
}


function Convert-PercentToWords {
  param(
    [Parameter(Mandatory)]
    [int]$Value
  )

  $unidades = @{
    0  = "zero"
    1  = "um"
    2  = "dois"
    3  = "três"
    4  = "quatro"
    5  = "cinco"
    6  = "seis"
    7  = "sete"
    8  = "oito"
    9  = "nove"
    10 = "dez"
    11 = "onze"
    12 = "doze"
    13 = "treze"
    14 = "quatorze"
    15 = "quinze"
    16 = "dezesseis"
    17 = "dezessete"
    18 = "dezoito"
    19 = "dezenove"
  }

  $dezenas = @{
    20 = "vinte"
    30 = "trinta"
    40 = "quarenta"
    50 = "cinquenta"
    60 = "sessenta"
    70 = "setenta"
    80 = "oitenta"
    90 = "noventa"
  }

  if ($Value -le 19) {
    return $unidades[$Value]
  }

  if ($Value -eq 100) {
    return "cem"
  }

  if ($Value -gt 100) {
    return "$Value"
  }

  $dezena = [Math]::Floor($Value / 10) * 10
  $unidade = $Value % 10

  if ($unidade -eq 0) {
    return $dezenas[$dezena]
  }

  return "$($dezenas[$dezena]) e $($unidades[$unidade])"
}


function Format-PercentContract {
  param(
    [Parameter(Mandatory)]
    [decimal]$Value
  )

  if ($Value -ne [Math]::Floor($Value)) {
    $culture = [System.Globalization.CultureInfo]::GetCultureInfo("pt-BR")
    return "$($Value.ToString('0.##', $culture))%"
  }

  $inteiro = [int]$Value
  $extenso = Convert-PercentToWords $inteiro

  return "$inteiro% ($extenso por cento)"
}


function Invoke-SigaGetComRetry {
  param(
    [Parameter(Mandatory)]
    [string]$Url,

    [int]$Tentativas = 5
  )

  for ($tentativa = 1; $tentativa -le $Tentativas; $tentativa++) {
    try {
      return Invoke-RestMethod `
        -Uri $Url `
        -Headers $sigaHeaders `
        -Method Get `
        -ErrorAction Stop
    }
    catch {
      if ($tentativa -eq $Tentativas) {
        throw
      }

      $espera = $tentativa * 2

      Write-Host "Falha temporária no SIGA. Aguardando $espera segundos..."

      Start-Sleep -Seconds $espera
    }
  }
}


function Get-SigaAluno {
  param(
    [Parameter(Mandatory)]
    [int]$AlunoId
  )

  $limit = 100
  $offset = 0

  while ($true) {
    Write-Host "Consultando alunos - offset $offset..."

    $url = "$sigaBaseUrl/lista_alunos_dados_sensiveis/?limit=$limit&offset=$offset"

    $response = Invoke-SigaGetComRetry -Url $url

    $aluno = $response.results |
      Where-Object {
        [int]$_.id -eq $AlunoId
      } |
      Select-Object -First 1

    if ($null -ne $aluno) {
      return $aluno
    }

    if ([string]::IsNullOrWhiteSpace($response.next)) {
      return $null
    }

    $offset += $limit
  }
}


function Get-SigaResponsaveis {
  param(
    [Parameter(Mandatory)]
    [int[]]$Ids
  )

  $limit = 100
  $offset = 0
  $encontrados = @()

  while ($true) {
    Write-Host "Consultando responsáveis - offset $offset..."

    $url = "$sigaBaseUrl/lista_responsaveis_dados_sensiveis/?unidade=1&limit=$limit&offset=$offset"

    $response = Invoke-SigaGetComRetry -Url $url

    foreach ($responsavel in $response.results) {
      if ([int]$responsavel.id -in $Ids) {
        $jaExiste = $encontrados |
          Where-Object {
            [int]$_.id -eq [int]$responsavel.id
          } |
          Select-Object -First 1

        if ($null -eq $jaExiste) {
          $encontrados += $responsavel

          Write-Host ""
          Write-Host "Responsável encontrado:"
          Write-Host "$($responsavel.id) - $(Repair-SigaEncoding $responsavel.nome)"
          Write-Host ""
        }
      }
    }

    if ($encontrados.Count -ge $Ids.Count) {
      return $encontrados
    }

    if ([string]::IsNullOrWhiteSpace($response.next)) {
      return $encontrados
    }

    $offset += $limit

    Start-Sleep -Milliseconds 250
  }
}


function Invoke-ClicksignRequest {
  param(
    [Parameter(Mandatory)]
    [ValidateSet("GET", "POST", "PATCH")]
    [string]$Method,

    [Parameter(Mandatory)]
    [string]$Url,

    $Body = $null
  )

  try {
    $params = @{
      Uri         = $Url
      Method      = $Method
      Headers     = $clicksignHeaders
      ErrorAction = "Stop"
    }

    Write-Host ""
    Write-Host "------------------------------------------------------------"
    Write-Host "$Method $Url"

    if ($null -ne $Body) {
      $json = $Body | ConvertTo-Json -Depth 50

      # PowerShell 5.1:
      # enviar explicitamente como UTF-8.
      $jsonBytes = [System.Text.Encoding]::UTF8.GetBytes($json)

      $params["Body"] = $jsonBytes
      $params["ContentType"] = "application/vnd.api+json"

      Write-Host ""
      Write-Host "BODY:"
      Write-Host $json
    }

    Write-Host "------------------------------------------------------------"

    return Invoke-RestMethod @params
  }
  catch {
    Write-Host ""
    Write-Host "============================================================"
    Write-Host "ERRO NA REQUISIÇÃO CLICKSIGN"
    Write-Host "============================================================"

    Write-Host ""
    Write-Host "$Method $Url"

    Write-Host ""
    Write-Host "ERRO:"
    Write-Host $_.Exception.Message

    if ($_.ErrorDetails.Message) {
      Write-Host ""
      Write-Host "ERROR DETAILS:"
      Write-Host $_.ErrorDetails.Message
    }

    if ($_.Exception.Response) {
      try {
        $response = $_.Exception.Response

        Write-Host ""
        Write-Host "STATUS HTTP:"
        Write-Host ([int]$response.StatusCode)
        Write-Host $response.StatusDescription

        $stream = $response.GetResponseStream()

        if ($null -ne $stream) {
          $reader = New-Object System.IO.StreamReader(
            $stream,
            [System.Text.Encoding]::UTF8
          )

          $responseBody = $reader.ReadToEnd()

          if (-not [string]::IsNullOrWhiteSpace($responseBody)) {
            Write-Host ""
            Write-Host "RESPOSTA DA CLICKSIGN:"
            Write-Host $responseBody
          }
        }
      }
      catch {}
    }

    throw
  }
}


function New-ClicksignQualificationRequirement {
  param(
    [Parameter(Mandatory)]
    [string]$EnvelopeId,

    [Parameter(Mandatory)]
    [string]$DocumentId,

    [Parameter(Mandatory)]
    [string]$SignerId,

    [Parameter(Mandatory)]
    [string]$Role
  )

  $body = @{
    data = @{
      type          = "requirements"

      attributes    = @{
        action = "agree"
        role   = $Role
      }

      relationships = @{
        document = @{
          data = @{
            type = "documents"
            id   = $DocumentId
          }
        }

        signer   = @{
          data = @{
            type = "signers"
            id   = $SignerId
          }
        }
      }
    }
  }

  Invoke-ClicksignRequest `
    -Method POST `
    -Url "$clicksignBaseUrl/envelopes/$EnvelopeId/requirements" `
    -Body $body |
    Out-Null
}


function New-ClicksignAuthenticationRequirement {
  param(
    [Parameter(Mandatory)]
    [string]$EnvelopeId,

    [Parameter(Mandatory)]
    [string]$DocumentId,

    [Parameter(Mandatory)]
    [string]$SignerId,

    [Parameter(Mandatory)]
    [ValidateSet("email", "whatsapp")]
    [string]$Auth
  )

  $body = @{
    data = @{
      type          = "requirements"

      attributes    = @{
        action = "provide_evidence"
        auth   = $Auth
      }

      relationships = @{
        document = @{
          data = @{
            type = "documents"
            id   = $DocumentId
          }
        }

        signer   = @{
          data = @{
            type = "signers"
            id   = $SignerId
          }
        }
      }
    }
  }

  Invoke-ClicksignRequest `
    -Method POST `
    -Url "$clicksignBaseUrl/envelopes/$EnvelopeId/requirements" `
    -Body $body |
    Out-Null
}


# ============================================================
# INÍCIO
# ============================================================

Write-Host ""
Write-Host "############################################################"
Write-Host "# CONTRATO 2027 - ALUNO ID $alunoId"
Write-Host "############################################################"


# ============================================================
# 1. ENTURMAÇÃO 2027
# ============================================================

Write-Host ""
Write-Host "Consultando enturmação 2027..."

$enturmacaoUrl = "$sigaBaseUrl/enturmacao_com_detalhes/?periodo=$periodo&aluno=$alunoId&limit=25"

$enturmacaoResponse = Invoke-SigaGetComRetry -Url $enturmacaoUrl

$enturmacao = $enturmacaoResponse.results |
  Where-Object {
    [int]$_.aluno_id -eq $alunoId
  } |
  Select-Object -First 1

if ($null -eq $enturmacao) {
  throw "Nenhuma enturmação 2027 encontrada para o aluno $alunoId."
}

$nomeTurmaCompleto = Repair-SigaEncoding $enturmacao.nome_turma_completo
$turnoAluno = Repair-SigaEncoding $enturmacao.turno
$situacaoAluno = Repair-SigaEncoding $enturmacao.situacao_aluno_turma

$partesTurma = $nomeTurmaCompleto -split "/"

if ($partesTurma.Count -lt 2) {
  throw "Não foi possível extrair a série de: $nomeTurmaCompleto"
}

$serieAluno = $partesTurma[1].Trim()

Write-Host "Turma completa : $nomeTurmaCompleto"
Write-Host "Turma ID       : $($enturmacao.turma_id)"
Write-Host "Série          : $serieAluno"
Write-Host "Turno          : $turnoAluno"
Write-Host "Situação       : $situacaoAluno"
Write-Host "Situação ID    : $($enturmacao.situacao_aluno_turma_id)"


# ============================================================
# 2. VALIDAR VALORES DA SÉRIE
# ============================================================

if (-not $valoresPorSerie.ContainsKey($serieAluno)) {
  Write-Host ""
  Write-Host "============================================================"
  Write-Host "VALORES NÃO CADASTRADOS"
  Write-Host "============================================================"
  Write-Host ""
  Write-Host "A aluna está na série:"
  Write-Host ""
  Write-Host "  $serieAluno"
  Write-Host ""
  Write-Host "Cadastre anuidade e desconto padrão dessa série em:"
  Write-Host ""
  Write-Host '  $valoresPorSerie'
  Write-Host ""
  Write-Host "Nenhum documento foi enviado."
  exit
}

$anuidadeValor = [decimal]$valoresPorSerie[$serieAluno].anuidade
$descontoPadrao = [decimal]$valoresPorSerie[$serieAluno].descontoPadrao

$anuidade = Format-Brl $anuidadeValor


# ============================================================
# 3. ALUNO
# ============================================================

Write-Host ""
Write-Host "Buscando cadastro da aluna..."

$aluno = Get-SigaAluno -AlunoId $alunoId

if ($null -eq $aluno) {
  throw "Aluno $alunoId não encontrado."
}

$nomeAluno = Repair-SigaEncoding $aluno.nome

Write-Host ""
Write-Host "Aluno encontrado:"
Write-Host "$nomeAluno - matrícula $($aluno.matricula)"


# ============================================================
# 4. RESPONSÁVEIS
# ============================================================

$responsavelIds = @(
  $aluno.responsavel_id
  $aluno.responsavel_secundario_id
  $aluno.mae_id
  $aluno.pai_id
) |
  Where-Object {
    $null -ne $_ -and "$_".Trim() -ne ""
  } |
  ForEach-Object {
    [int]$_
  } |
  Sort-Object -Unique

Write-Host ""
Write-Host "Buscando responsáveis..."

$responsaveis = Get-SigaResponsaveis -Ids $responsavelIds

$responsavelPrincipal = $responsaveis |
  Where-Object {
    [int]$_.id -eq [int]$aluno.responsavel_id
  } |
  Select-Object -First 1

$responsavelPedagogico = $responsaveis |
  Where-Object {
    [int]$_.id -eq [int]$aluno.responsavel_secundario_id
  } |
  Select-Object -First 1

$mae = $responsaveis |
  Where-Object {
    [int]$_.id -eq [int]$aluno.mae_id
  } |
  Select-Object -First 1

$pai = $responsaveis |
  Where-Object {
    [int]$_.id -eq [int]$aluno.pai_id
  } |
  Select-Object -First 1

if ($null -eq $responsavelPrincipal) {
  throw "Responsável principal/contratante não encontrado."
}

if ($null -eq $responsavelPedagogico) {
  throw "Responsável secundário/pedagógico não encontrado."
}


# ============================================================
# 5. DESCONTOS 2027
# ============================================================

Write-Host ""
Write-Host "Consultando descontos..."

$descontosUrl = "$sigaBaseUrl/lista_alunos_com_descontos/?aluno_id=$alunoId&limit=25"

$descontosResponse = Invoke-SigaGetComRetry -Url $descontosUrl

$registroDescontos = $descontosResponse.results |
  Where-Object {
    [int]$_.id -eq $alunoId
  } |
  Select-Object -First 1

$descontos2027 = @()

if ($null -ne $registroDescontos) {
  $descontos2027 = @(
    $registroDescontos.descontos |
      Where-Object {
        $dataInicial = [DateTime]::Parse($_.data_inicial)
        $dataFinal = [DateTime]::Parse($_.data_final)

        $vigente2027 =
        $dataInicial -le [DateTime]"2027-12-31" -and
        $dataFinal -ge [DateTime]"2027-01-01"

        $mesmaTurma =
        [int]$_.id_turma -eq [int]$enturmacao.turma_id

        $vigente2027 -and $mesmaTurma
      }
  )
}


# ============================================================
# 6. CALCULAR DESCONTOS
# ============================================================

$descontoSiga = [decimal]0

foreach ($desconto in $descontos2027) {
  if ($null -ne $desconto.percentual_abatimento) {
    $descontoSiga += [decimal]$desconto.percentual_abatimento
  }
}

$descontoTotal = $descontoPadrao + $descontoSiga

if ($descontoTotal -gt 100) {
  throw "O desconto total calculado ultrapassou 100%."
}

$descontoVencimento = Format-PercentContract $descontoTotal


# ============================================================
# 7. NORMALIZAR DADOS
# ============================================================

$nomeResponsavelPrincipal = Repair-SigaEncoding $responsavelPrincipal.nome
$nomeResponsavelPedagogico = Repair-SigaEncoding $responsavelPedagogico.nome

$filiacao1 = ""
$filiacao2 = ""

if ($null -ne $mae) {
  $filiacao1 = Repair-SigaEncoding $mae.nome
}

if ($null -ne $pai) {
  $filiacao2 = Repair-SigaEncoding $pai.nome
}

$logradouroContratante = Repair-SigaEncoding $responsavelPrincipal.logradouro
$cidadeContratante = Repair-SigaEncoding $responsavelPrincipal.cidade

$telefoneResponsavel = Convert-PhoneToClicksign `
  $responsavelPrincipal.celular

if ([string]::IsNullOrWhiteSpace($telefoneResponsavel)) {
  throw "Telefone do contratante inválido para a Clicksign."
}

$cpfResponsavelClicksign = $responsavelPrincipal.cpf_cnpj

$dataNascimentoResponsavel = Convert-DateToIsoDate `
  $responsavelPrincipal.data_nascimento


# ============================================================
# 8. DADOS DO MODELO
# ============================================================

$templateData = [ordered]@{
  "nome aluno"           = $nomeAluno
  "filiacao 1"           = $filiacao1
  "filiacao 2"           = $filiacao2

  "data nasc aluno"      = Convert-DateToContract $aluno.data_nascimento

  "rg aluno"             = $aluno.rg
  "cpf aluno"            = $aluno.cpf

  "anuidade"             = $anuidade

  "nome contratante"     = $nomeResponsavelPrincipal
  "rg contratante"       = $responsavelPrincipal.rg
  "cpf contratante"      = $responsavelPrincipal.cpf_cnpj

  "endereco contratante" = $logradouroContratante
  "cidade contratante"   = $cidadeContratante
  "estado contratante"   = $responsavelPrincipal.uf
  "cep contratante"      = $responsavelPrincipal.cep

  "celular contratante"  = $responsavelPrincipal.celular
  "email contratante"    = $responsavelPrincipal.email

  "nome resp pedagógico" = $nomeResponsavelPedagogico

  "serie aluno"          = $serieAluno
  "turno aluno"          = $turnoAluno

  "descvencto"           = $descontoVencimento
}


# ============================================================
# 9. CONFERÊNCIA
# ============================================================

Write-Host ""
Write-Host "============================================================"
Write-Host "DADOS DO CONTRATO"
Write-Host "============================================================"

$templateData.GetEnumerator() |
  ForEach-Object {
    Write-Host "$($_.Key): $($_.Value)"
  }


Write-Host ""
Write-Host "============================================================"
Write-Host "COMPOSIÇÃO DO DESCONTO"
Write-Host "============================================================"

Write-Host ""
Write-Host "Desconto padrão da série: $descontoPadrao%"

if ($descontos2027.Count -eq 0) {
  Write-Host "Nenhum desconto adicional de 2027 encontrado no SIGA."
}
else {
  foreach ($desconto in $descontos2027) {
    $nomeDesconto = Repair-SigaEncoding $desconto.nome_abatimento

    Write-Host ""
    Write-Host "$nomeDesconto"
    Write-Host "  Percentual : $($desconto.percentual_abatimento)%"
    Write-Host "  Tipo       : $($desconto.tipo_desconto)"
    Write-Host "  Bolsa ID   : $($desconto.id_bolsa)"
  }
}

Write-Host ""
Write-Host "Desconto adicional SIGA : $descontoSiga%"
Write-Host "Desconto total           : $descontoVencimento"


Write-Host ""
Write-Host "============================================================"
Write-Host "SIGNATÁRIOS"
Write-Host "============================================================"

Write-Host ""
Write-Host "RESPONSÁVEL:"
Write-Host "Nome         : $nomeResponsavelPrincipal"
Write-Host "CPF          : $cpfResponsavelClicksign"
Write-Host "Nascimento   : $dataNascimentoResponsavel"
Write-Host "WhatsApp     : $telefoneResponsavel"
Write-Host "E-mail       : $($responsavelPrincipal.email)"
Write-Host "Envio        : WhatsApp"

Write-Host ""
Write-Host "DIRETORA:"
Write-Host "Nome         : $diretoraNome"
Write-Host "CPF          : $diretoraCpf"
Write-Host "Nascimento   : $diretoraNascimento"
Write-Host "E-mail       : $diretoraEmail"
Write-Host "Envio        : E-mail"

Write-Host ""
Write-Host "Prazo para assinatura: $prazoAssinaturaDias dias"


# ============================================================
# 10. VALIDAÇÕES
# ============================================================

$erros = @()

if (
  [string]::IsNullOrWhiteSpace($templateKey) -or
  $templateKey -eq "COLE_AQUI_A_TEMPLATE_KEY"
) {
  $erros += "templateKey"
}

if ([string]::IsNullOrWhiteSpace($responsavelPrincipal.email)) {
  $erros += "e-mail do responsável"
}

if ([string]::IsNullOrWhiteSpace($cpfResponsavelClicksign)) {
  $erros += "CPF do responsável"
}

if ([string]::IsNullOrWhiteSpace($telefoneResponsavel)) {
  $erros += "telefone do responsável"
}

if ($erros.Count -gt 0) {
  Write-Host ""
  Write-Host "============================================================"
  Write-Host "ENVIO BLOQUEADO"
  Write-Host "============================================================"

  foreach ($erro in $erros) {
    Write-Host " - $erro"
  }

  exit
}


# ============================================================
# 11. MODO CONFERÊNCIA
# ============================================================

if (-not $confirmarEnvio) {
  Write-Host ""
  Write-Host "============================================================"
  Write-Host "NENHUM DOCUMENTO FOI ENVIADO"
  Write-Host "============================================================"
  Write-Host ""
  Write-Host "Confira principalmente:"
  Write-Host ""
  Write-Host "  Série ............: $serieAluno"
  Write-Host "  Anuidade .........: $anuidade"
  Write-Host "  Desconto padrão ..: $descontoPadrao%"
  Write-Host "  Desconto SIGA ....: $descontoSiga%"
  Write-Host "  Total ............: $descontoVencimento"
  Write-Host ""
  Write-Host "Se estiver tudo correto, altere:"
  Write-Host ""
  Write-Host '  $confirmarEnvio = $true'
  Write-Host ""
  exit
}


# ============================================================
# 12. PRAZO DE ASSINATURA
# ============================================================

$deadlineAt = (Get-Date).
ToUniversalTime().
AddDays($prazoAssinaturaDias).
ToString("yyyy-MM-ddTHH:mm:ssZ")


# ============================================================
# 13. CRIAR ENVELOPE
# ============================================================

Write-Host ""
Write-Host "============================================================"
Write-Host "1. CRIANDO ENVELOPE"
Write-Host "============================================================"

$envelopeBody = @{
  data = @{
    type          = "envelopes"

    attributes    = @{
      name                = "CONTRATO DE PRESTAÇÃO DE SERVIÇOS EDUCACIONAIS - $nomeAluno"

      locale              = "pt-BR"
      auto_close          = $true
      remind_interval     = 3
      block_after_refusal = $false

      deadline_at         = $deadlineAt
    }

    relationships = @{
      folder = @{
        data = @{
          type = "folders"
          id   = $folderId
        }
      }
    }
  }
}

$envelopeResponse = Invoke-ClicksignRequest `
  -Method POST `
  -Url "$clicksignBaseUrl/envelopes" `
  -Body $envelopeBody

$envelopeId = $envelopeResponse.data.id

if ([string]::IsNullOrWhiteSpace($envelopeId)) {
  throw "A Clicksign não retornou o ID do envelope."
}

Write-Host ""
Write-Host "Envelope criado:"
Write-Host $envelopeId


# ============================================================
# 14. DOCUMENTO PELO MODELO
# ============================================================

Write-Host ""
Write-Host "============================================================"
Write-Host "2. GERANDO DOCUMENTO"
Write-Host "============================================================"

$documentBody = @{
  data = @{
    type       = "documents"

    attributes = @{
      filename = "CONTRATO DE PRESTAÇÃO DE SERVIÇOS EDUCACIONAIS - $nomeAluno.docx"

      template = @{
        key  = $templateKey
        data = $templateData
      }
    }
  }
}

$documentResponse = Invoke-ClicksignRequest `
  -Method POST `
  -Url "$clicksignBaseUrl/envelopes/$envelopeId/documents" `
  -Body $documentBody

$documentId = $documentResponse.data.id

if ([string]::IsNullOrWhiteSpace($documentId)) {
  throw "A Clicksign não retornou o ID do documento."
}


# ============================================================
# 15. SIGNATÁRIO RESPONSÁVEL
# ============================================================

Write-Host ""
Write-Host "============================================================"
Write-Host "3. CRIANDO SIGNATÁRIO RESPONSÁVEL"
Write-Host "============================================================"

$responsavelSignerBody = @{
  data = @{
    type       = "signers"

    attributes = @{
      name                      = $nomeResponsavelPrincipal
      email                     = $responsavelPrincipal.email

      phone_number              = $telefoneResponsavel

      birthday                  = $dataNascimentoResponsavel

      has_documentation         = $true
      documentation             = $cpfResponsavelClicksign

      refusable                 = $false
      group                     = 1
      location_required_enabled = $false

      communicate_events        = @{
        signature_request  = "whatsapp"
        signature_reminder = "none"
        document_signed    = "whatsapp"
      }
    }
  }
}

$responsavelSignerResponse = Invoke-ClicksignRequest `
  -Method POST `
  -Url "$clicksignBaseUrl/envelopes/$envelopeId/signers" `
  -Body $responsavelSignerBody

$responsavelSignerId = $responsavelSignerResponse.data.id


# ============================================================
# 16. REQUISITOS RESPONSÁVEL
# ============================================================

New-ClicksignQualificationRequirement `
  -EnvelopeId $envelopeId `
  -DocumentId $documentId `
  -SignerId $responsavelSignerId `
  -Role "contractor"

New-ClicksignAuthenticationRequirement `
  -EnvelopeId $envelopeId `
  -DocumentId $documentId `
  -SignerId $responsavelSignerId `
  -Auth "whatsapp"


# ============================================================
# 17. SIGNATÁRIA DIRETORA
# ============================================================

Write-Host ""
Write-Host "============================================================"
Write-Host "4. CRIANDO SIGNATÁRIA DIRETORA"
Write-Host "============================================================"

$diretoraSignerBody = @{
  data = @{
    type       = "signers"

    attributes = @{
      name                      = $diretoraNome
      email                     = $diretoraEmail
      birthday                  = $diretoraNascimento

      has_documentation         = $true
      documentation             = $diretoraCpf

      refusable                 = $false
      group                     = 1
      location_required_enabled = $false

      communicate_events        = @{
        signature_request  = "email"
        signature_reminder = "email"
        document_signed    = "email"
      }
    }
  }
}

$diretoraSignerResponse = Invoke-ClicksignRequest `
  -Method POST `
  -Url "$clicksignBaseUrl/envelopes/$envelopeId/signers" `
  -Body $diretoraSignerBody

$diretoraSignerId = $diretoraSignerResponse.data.id


# ============================================================
# 18. REQUISITOS DIRETORA
# ============================================================

New-ClicksignQualificationRequirement `
  -EnvelopeId $envelopeId `
  -DocumentId $documentId `
  -SignerId $diretoraSignerId `
  -Role "contractee"

New-ClicksignAuthenticationRequirement `
  -EnvelopeId $envelopeId `
  -DocumentId $documentId `
  -SignerId $diretoraSignerId `
  -Auth "email"


# ============================================================
# 19. ATIVAR ENVELOPE
# ============================================================

Write-Host ""
Write-Host "============================================================"
Write-Host "5. ATIVANDO ENVELOPE"
Write-Host "============================================================"

$activateBody = @{
  data = @{
    id         = $envelopeId
    type       = "envelopes"

    attributes = @{
      status = "running"
    }
  }
}

Invoke-ClicksignRequest `
  -Method PATCH `
  -Url "$clicksignBaseUrl/envelopes/$envelopeId" `
  -Body $activateBody |
  Out-Null


# ============================================================
# 20. NOTIFICAR
# ============================================================

Write-Host ""
Write-Host "============================================================"
Write-Host "6. ENVIANDO NOTIFICAÇÕES"
Write-Host "============================================================"

$notificationBody = @{
  data = @{
    type       = "notifications"
    attributes = @{}
  }
}

Invoke-ClicksignRequest `
  -Method POST `
  -Url "$clicksignBaseUrl/envelopes/$envelopeId/notifications" `
  -Body $notificationBody |
  Out-Null


# ============================================================
# RESULTADO
# ============================================================

Write-Host ""
Write-Host "############################################################"
Write-Host "# CONTRATO ENVIADO"
Write-Host "############################################################"

Write-Host ""
Write-Host "Aluno       : $nomeAluno"
Write-Host "Aluno ID    : $alunoId"
Write-Host "Matrícula   : $($aluno.matricula)"
Write-Host "Série       : $serieAluno"
Write-Host "Anuidade    : $anuidade"
Write-Host "Desconto    : $descontoVencimento"
Write-Host ""
Write-Host "Envelope ID : $envelopeId"
Write-Host "Documento ID: $documentId"
Write-Host ""
Write-Host "Responsável : $nomeResponsavelPrincipal"
Write-Host "WhatsApp    : $telefoneResponsavel"
Write-Host ""
Write-Host "Diretora    : $diretoraNome"
Write-Host "E-mail      : $diretoraEmail"
Write-Host ""
Write-Host "Prazo       : $prazoAssinaturaDias dias"
Write-Host "Limite UTC  : $deadlineAt"
Write-Host ""