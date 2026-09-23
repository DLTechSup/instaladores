[Net.ServicePointManager]::SecurityProtocol = 'Tls12'
$ProgressPreference = 'SilentlyContinue'
$base = "https://github.com/DLTechSup/instaladores/releases/download/v1"
$tmp  = "$env:TEMP\inst"
New-Item $tmp -ItemType Directory -Force | Out-Null

$apps = @(
  @("Firefox.Setup.60.0esr.exe",            "-ms"),
  @("jre-8u341-windows-i586.exe",           "/s AUTO_UPDATE=0 SPONSORS=0 REBOOT=0"),
  @("iview454_setup.exe",                   "/silent /allusers=1 /desktop=1 /group=1 /assoc=1"),
  @("irfanview_lang_portugues-brasil.exe",  "/silent")
)

foreach ($a in $apps) {
  Write-Host "Instalando $($a[0])..."
  Invoke-WebRequest "$base/$($a[0])" -OutFile "$tmp\$($a[0])" -UseBasicParsing
  Start-Process "$tmp\$($a[0])" -ArgumentList $a[1] -Wait
}
Remove-Item $tmp -Recurse -Force
Write-Host "Concluido."
