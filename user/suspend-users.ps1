<#
.SINOPSE
  Suspende usuários no Active Directory e no Google Workspace (GAM), com modo único ou por CSV.

.DESCRIÇÃO
  Este script:
    - Gera uma senha temporária segura.
    - No Active Directory:
        - Redefine a senha
        - Marca "alterar senha no próximo logon"
        - Desabilita a conta
        - Move o usuário para a OU "Contas Suspensas"
        - Faz backup dos grupos AD e remove o usuário desses grupos
    - No Google Workspace (via GAM):
        - Faz backup dos grupos do usuário
        - Troca a senha, força troca no próximo login
        - Remove o usuário de todos os grupos
        - Suspende o usuário e move para a org "/Contas Suspensas"
  Os backups (txt/csv temporário) são salvos em:
    C:\Users\dnunes\Downloads\usuarios-suspensos

.EXEMPLO
  .\suspenderUsuarios.ps1

.NOTAS
  Autor: Diogo
  Criado em: 01/08/2025
  Atualizado em: 12/02/2026

  Changelog:
    - 01/08/2025 v1.0 - Criação do script
    - 12/02/2026 v1.1 - Correção de geração de senha e filtro do Get-ADUser; padronização de backups em Downloads
#>

# Força o encoding UTF-8 com BOM para compatibilidade e limpa o terminal
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8BOM'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Clear-Host

# =========================
# Configurações
# =========================

# Pasta obrigatória para arquivos locais (logs, temporários, backups)
$backupDir = "C:\Scripts\usuarios-suspensos"

# OU de destino no AD
$targetOuDn = "OU=Contas Suspensas,DC=csfa,DC=com,DC=br"

# Org Unit de destino no Google (GAM)
$googleOrgPath = "/Contas Suspensas"

# Cria pasta de backup se não existir
if (-not (Test-Path $backupDir)) {
  New-Item -ItemType Directory -Path $backupDir | Out-Null
}

# =========================
# Funções auxiliares
# =========================

function New-SecurePassword {
  param(
    [int]$Length = 12,
    [int]$MinSpecial = 2
  )

  # Conjuntos de caracteres
  $lower = "abcdefghijkmnopqrstuvwxyz"
  $upper = "ABCDEFGHJKLMNPQRSTUVWXYZ"
  $digits = "23456789"
  $special = "!@#$%*-_+?"
  $all = ($lower + $upper + $digits + $special).ToCharArray()

  # Garante mínimo de especiais
  $chars = New-Object System.Collections.Generic.List[char]

  $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()

  function Get-RandomChar([char[]]$set) {
    $b = New-Object byte[] 4
    $rng.GetBytes($b)
    $idx = [BitConverter]::ToUInt32($b, 0) % $set.Length
    return $set[$idx]
  }

  for ($i = 0; $i -lt $MinSpecial; $i++) {
    $chars.Add((Get-RandomChar($special.ToCharArray())))
  }

  # Completa o restante
  while ($chars.Count -lt $Length) {
    $chars.Add((Get-RandomChar($all)))
  }

  # Embaralha
  for ($i = $chars.Count - 1; $i -gt 0; $i--) {
    $b = New-Object byte[] 4
    $rng.GetBytes($b)
    $j = [BitConverter]::ToUInt32($b, 0) % ($i + 1)

    $tmp = $chars[$i]
    $chars[$i] = $chars[$j]
    $chars[$j] = $tmp
  }

  $rng.Dispose()
  return (-join $chars)
}

function Write-Utf8NoBomFile {
  param(
    [Parameter(Mandatory)]
    [string]$Path,

    [Parameter(Mandatory)]
    [string[]]$Lines
  )

  # UTF-8 sem BOM (compatível com Windows PowerShell)
  $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllLines($Path, $Lines, $utf8NoBom)
}

function Invoke-GamCapture {
  param(
    [Parameter(Mandatory)]
    [string[]]$Arguments
  )

  # Executa o GAM capturando a saída (stdout + stderr) para o PowerShell
  # Observação: se o GAM estiver como gam.exe no PATH, o & gam funciona.
  $output = & gam @Arguments 2>&1
  return @($output)
}

# =========================
# Função principal
# =========================

function SuspenderUsuario {
  param(
    [Parameter(Mandatory)]
    [string]$adusername,

    [string]$email
  )

  Write-Host ""
  Write-Host "========================================" -ForegroundColor Cyan
  Write-Host "Processando: $adusername" -ForegroundColor Cyan
  Write-Host "========================================" -ForegroundColor Cyan

  # Gera senha segura (substitui System.Web.Security.Membership)
  $password = New-SecurePassword -Length 12 -MinSpecial 2

  # Busca usuário no AD (evita erro do -Filter com variável)
  try {
    $adUser = Get-ADUser -Identity $adusername -Properties EmailAddress, DistinguishedName
  }
  catch {
    $adUser = $null
  }

  if (-not $adUser) {
    Write-Warning "Conta AD '$adusername' não encontrada."
    return
  }

  # Se email não foi informado, tenta pegar do AD
  if (-not $email) {
    $email = $adUser.EmailAddress
  }

  if (-not $email) {
    Write-Warning "Usuário '$adusername' não tem e-mail cadastrado no AD e não foi informado no CSV."
    return
  }

  # ---------- AD: altera senha, desabilita e move OU ----------
  try {
    Set-ADAccountPassword -Identity $adusername -NewPassword (ConvertTo-SecureString $password -AsPlainText -Force)
    Set-ADUser -Identity $adusername -ChangePasswordAtLogon $true -PasswordNeverExpires $false -Enabled $false

    # Move para OU de suspensos
    Move-ADObject -Identity $adUser.DistinguishedName -TargetPath $targetOuDn

    Write-Host "AD: usuário desabilitado, senha redefinida e movido para 'Contas Suspensas'." -ForegroundColor Yellow
  }
  catch {
    Write-Warning "Falha ao suspender no AD ($adusername): $($_.Exception.Message)"
    return
  }

  # ---------- AD: backup e remoção de grupos ----------
  $gruposAD = @()
  try {
    $gruposAD = Get-ADPrincipalGroupMembership -Identity $adusername |
      Where-Object { $_.Name -ne "Usuários do domínio" }
  }
  catch {
    $gruposAD = @()
  }

  $gruposADList = @()
  if ($gruposAD.Count -gt 0) {
    $gruposADList = $gruposAD | Select-Object -ExpandProperty Name
  }

  # ---------- Google: backup de grupos ----------
  $tempGoogleGroupsCsv = Join-Path $backupDir "$adusername`_google_groups.csv"

  $googleGroupsOut = Invoke-GamCapture -Arguments @("user", $email, "print", "groups")
  Write-Utf8NoBomFile -Path $tempGoogleGroupsCsv -Lines $googleGroupsOut

  # ---------- Salva backup final (AD + Google) ----------
  $saidaPath = Join-Path $backupDir "$adusername`_grupos_completos.txt"

  $saida = @()
  $saida += "Grupos AD:"
  if ($gruposADList.Count -gt 0) {
    $saida += $gruposADList
  }
  else {
    $saida += "(nenhum grupo além de 'Usuários do domínio' ou falha ao listar)"
  }

  $saida += ""
  $saida += "Grupos Google Workspace (via GAM):"
  if ($googleGroupsOut.Count -gt 0) {
    $saida += $googleGroupsOut
  }
  else {
    $saida += "(nenhum output retornado)"
  }

  $saida | Out-File -FilePath $saidaPath -Encoding utf8BOM

  # Remove de grupos AD (depois do backup)
  if ($gruposAD.Count -gt 0) {

    foreach ($grupo in $gruposAD) {

      try {
        Remove-ADGroupMember -Identity $grupo.DistinguishedName `
          -Members $adusername `
          -Confirm:$false `
          -ErrorAction Stop

        Write-Host "AD: removido de '$($grupo.Name)'" -ForegroundColor DarkYellow

      }
      catch {
        Write-Warning "Falha ao remover '$adusername' do grupo '$($grupo.Name)': $($_.Exception.Message)"
      }

    }

    Write-Host "AD: remoção de grupos concluída. Backup salvo em: $saidaPath" -ForegroundColor Yellow

  }
  else {

    Write-Host "AD: nenhum grupo para remover (backup salvo em: $saidaPath)" -ForegroundColor Yellow

  }

  # Remove CSV temporário do Google (opcional; se você quiser manter, comente a linha abaixo)
  Remove-Item $tempGoogleGroupsCsv -ErrorAction SilentlyContinue

  # ---------- Google: altera senha, remove grupos, suspende ----------
  try {
    $null = Invoke-GamCapture -Arguments @("update", "user", $email, "password", $password, "nohash", "changepassword", "on")
    $null = Invoke-GamCapture -Arguments @("user", $email, "delete", "groups")
    $null = Invoke-GamCapture -Arguments @("update", "user", $email, "suspended", "on", "org", $googleOrgPath)

    Write-Host "Google: usuário suspenso, senha alterada e removido de grupos." -ForegroundColor Yellow
    Write-Host "Senha temporária (AD + Google): $password" -ForegroundColor DarkYellow
  }
  catch {
    Write-Warning "Falha ao suspender no Google (GAM) para '$email': $($_.Exception.Message)"
    Write-Host "Senha temporária gerada: $password" -ForegroundColor DarkYellow
  }
}

# =========================
# Execução
# =========================

$modo = Read-Host "Modo único (U) ou CSV (C)?"

if ($modo.ToUpper() -eq "U") {

  $adusername = Read-Host "Digite o SamAccountName"
  SuspenderUsuario -adusername $adusername -email ""

}
elseif ($modo.ToUpper() -eq "C") {

  $caminho = Read-Host "Caminho do CSV (ex: C:\Users\dnunes\Downloads\suspensos.csv)"

  if (-not (Test-Path $caminho)) {
    Write-Warning "CSV não encontrado: $caminho"
    return
  }

  $usuarios = Import-Csv $caminho

  foreach ($u in $usuarios) {

    $adusername = $u.adusername
    $email = $u.email

    if (-not $adusername) {
      Write-Warning "Linha inválida (sem adusername): $($u | Out-String)"
      continue
    }

    # Se não veio email no CSV, tenta buscar no AD
    if (-not $email) {
      try {
        $found = Get-ADUser -Identity $adusername -Properties EmailAddress
        $email = $found.EmailAddress
      }
      catch {
        $email = $null
      }
    }

    if ($email) {
      SuspenderUsuario -adusername $adusername -email $email
    }
    else {
      Write-Warning "Não foi possível determinar o e-mail do usuário '$adusername' (CSV e AD sem email)."
    }
  }

}
else {

  Write-Warning "Opção inválida. Escolha U ou C."

}

Write-Host ""
Write-Host "Fim. Não esqueça: SAS, SIGA, ClassApp e Cantina." -ForegroundColor Cyan
