<#
.SINOPSE
    Adicionar sinopse aqui

.DESCRIÇÃO
    Adicionar descrição detalhada aqui

.EXEMPLO
    .\downloadYT-Dlp.ps1

.NOTAS
    Autor: Diogo
    Última atualização: 03/04/2025
#>

﻿$links = Import-Csv "D:\Downloads\links.csv"

foreach ($link in $links) {

$url = $link.link

yt-dlp -x --audio-format mp3 "$url" -o "D:\Downloads\mm\%(title)s.%(ext)s"

}