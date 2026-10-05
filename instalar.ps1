try { [Net.ServicePointManager]::SecurityProtocol = 3072 } catch {}
$wc = New-Object Net.WebClient
$ProgressPreference = 'SilentlyContinue'
$base = "https://github.com/DLTechSup/instaladores/releases/download/v1"
$tmp  = "$env:TEMP\inst"
New-Item $tmp -ItemType Directory -Force | Out-Null

$apps = @(
  @("IrfanView",            "03.iview454_setup.exe",                  "/silent /allusers=1 /desktop=1 /group=1 /assoc=1"),
  @("IrfanView Portugues",  "04.irfanview_lang_portugues-brasil.exe", "/silent"),
  @("Firefox 60 ESR",       "05.Firefox.Setup.60.0esr.exe",           "-ms"),
  @("Java 8",               "06.jre-8u341-windows-i586.exe",          "/s AUTO_UPDATE=0 SPONSORS=0 REBOOT=0"),
  @("PDF24 Creator",        "07.pdf24-creator-9.2.2.exe",             "/VERYSILENT /SUPPRESSMSGBOXES /NORESTART"),
  @("WinRAR",               "09.winrar-x32-611br.exe",                "/S"),
  @("FG TimeSync",          "11.FGTimeSyncSetup_1.0.0.4.exe",         "/VERYSILENT /SUPPRESSMSGBOXES /NORESTART")
)

Write-Host "`n=== DLTechSup - Instaladores ===" -ForegroundColor Cyan
for ($n = 0; $n -lt $apps.Count; $n++) {
  Write-Host ("  [{0}] {1}" -f ($n + 1), $apps[$n][0])
}
Write-Host "  [T] Instalar todos"
Write-Host "  [0] Sair"
Write-Host "`nDigite os numeros separados por virgula ou espaco (ex: 1,3,5) ou T para todos."
$sel = Read-Host "Escolha"

if ($sel -match '^\s*(0|s|sair)?\s*$') { Write-Host "Nada selecionado. Saindo."; return }

if ($sel -match '^\s*(t|todos|all)\s*$') {
  $apps = $apps
} else {
  $idx = @($sel -split '[,\s;]+' | Where-Object { $_ -match '^\d+$' } | ForEach-Object { [int]$_ } |
           Where-Object { $_ -ge 1 -and $_ -le $apps.Count } | Sort-Object -Unique)
  if ($idx.Count -eq 0) { Write-Host "Selecao invalida." -ForegroundColor Red; return }
  $apps = @($idx | ForEach-Object { ,$apps[$_ - 1] })
}

$i = 0
foreach ($a in $apps) {
  $i++
  $ProgressPreference = 'Continue'
  Write-Progress -Activity "Instalando programas" -Status "$i de $($apps.Count) - $($a[0])" -PercentComplete (($i - 1) / $apps.Count * 100)
  $ProgressPreference = 'SilentlyContinue'

  Write-Host "[$i/$($apps.Count)] $($a[0])... " -NoNewline
  try {
    $wc.DownloadFile("$base/$($a[1])", "$tmp\$($a[1])")
    Start-Process "$tmp\$($a[1])" -ArgumentList $a[2] -Wait
    Write-Host "Concluido" -ForegroundColor Green
  } catch {
    Write-Host "Falhou: $($_.Exception.Message)" -ForegroundColor Red
  }
}

Write-Progress -Activity "Instalando programas" -Status "Fim" -Completed
Remove-Item $tmp -Recurse -Force
Write-Host "`nInstalacoes finalizadas." -ForegroundColor Cyan
