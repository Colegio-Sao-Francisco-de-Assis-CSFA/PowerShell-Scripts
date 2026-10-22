$tokenSeguro = "9ea45280a8f5c0b30dad"

$payload = @{
  messageData = @{
    subject    = "Teste de mensagem personalizada"
    content    = "<p>Olá, Phellipe!</p><p>Segue abaixo o link:</p><p><a href='https://example.com/?aluno=1010'>Acessar link de teste</a></p>"
    type       = "comunicado"
    noReply    = $false
    recipients = @{
      eids = @("1010")
    }
  }
} | ConvertTo-Json -Depth 10

$resposta = Invoke-RestMethod `
  -Method Post `
  -Uri "https://api.classapp.com.br/v1/message" `
  -Headers @{
  Authorization = "Bearer $tokenSeguro"
} `
  -ContentType "application/json; charset=utf-8" `
  -Body ([System.Text.Encoding]::UTF8.GetBytes($payload)) `
  -ErrorAction Stop

$resposta | ConvertTo-Json -Depth 10