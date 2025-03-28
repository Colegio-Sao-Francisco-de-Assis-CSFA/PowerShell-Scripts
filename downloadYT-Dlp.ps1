$links = Import-Csv "D:\Downloads\links.csv"

foreach ($link in $links) {

$url = $link.link

yt-dlp -x --audio-format mp3 "$url" -o "D:\Downloads\mm\%(title)s.%(ext)s"

}