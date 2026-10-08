param()

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$clicksignToken = "fd44f104-e153-490c-a746-730f9698efab"

$headers = @{
  Authorization = $clicksignToken
  Accept        = "application/vnd.api+json"
}

$url = "https://app.clicksign.com/api/v3/folders"

try {
  $response = Invoke-RestMethod `
    -Uri $url `
    -Method GET `
    -Headers $headers `
    -ErrorAction Stop

  Write-Host ""
  Write-Host "============================================================"
  Write-Host "PASTAS DA CLICKSIGN"
  Write-Host "============================================================"

  foreach ($folder in $response.data) {
    Write-Host ""
    Write-Host "Nome : $($folder.attributes.name)"
    Write-Host "Path : $($folder.attributes.path)"
    Write-Host "ID   : $($folder.id)"
  }
}
catch {
  Write-Host ""
  Write-Host "ERRO:"
  Write-Host $_.Exception.Message

  if ($_.ErrorDetails.Message) {
    Write-Host ""
    Write-Host $_.ErrorDetails.Message
  }
}