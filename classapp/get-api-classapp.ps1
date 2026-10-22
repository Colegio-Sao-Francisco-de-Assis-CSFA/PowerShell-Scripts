# 9ea45280a8f5c0b30dad
$tokenSeguro = "9ea45280a8f5c0b30dad"

$resultado = Invoke-RestMethod `
  -Method Get `
  -Uri "https://api.classapp.com.br/v1/student?disabled=false" `
  -Headers @{
  Authorization = "Bearer $($tokenSeguro)"
}

$resultado | ConvertTo-Json -Depth 10