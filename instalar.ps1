try { [Net.ServicePointManager]::SecurityProtocol = 3072 } catch {}
$wc = New-Object Net.WebClient
$ProgressPreference = 'SilentlyContinue'
$base = "https://github.com/DLTechSup/instaladores/releases/download/v1"
$tmp  = "$env:TEMP\inst"

# Nome, arquivo, args de instalacao, nome no Windows (para remover), args de remocao silenciosa
$apps = @(
  @("IrfanView",            "03.iview454_setup.exe",                  "/silent /allusers=1 /desktop=1 /group=1 /assoc=1", "IrfanView [0-9]*",    "/silent"),
  @("IrfanView Portugues",  "04.irfanview_lang_portugues-brasil.exe", "/silent",                                          "IrfanView*Lang*",     "/silent"),
  @("Firefox 60 ESR",       "05.Firefox.Setup.60.0esr.exe",           "-ms",                                              "Mozilla Firefox*",    "/S"),
  @("Java 8",               "06.jre-8u341-windows-i586.exe",          "/s AUTO_UPDATE=0 SPONSORS=0 REBOOT=0",             "Java 8*",             "/qn /norestart"),
  @("PDF24 Creator",        "07.pdf24-creator-9.2.2.exe",             "/VERYSILENT /SUPPRESSMSGBOXES /NORESTART",         "PDF24*",              "/VERYSILENT /SUPPRESSMSGBOXES /NORESTART"),
  @("WinRAR",               "09.winrar-x32-611br.exe",                "/S",                                               "WinRAR*",             "/S"),
  @("FG TimeSync",          "11.FGTimeSyncSetup_1.0.0.4.exe",         "/VERYSILENT /SUPPRESSMSGBOXES /NORESTART",         "*TimeSync*",          "/VERYSILENT /SUPPRESSMSGBOXES /NORESTART")
)

function Get-Instalado($padrao) {
  $chaves = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
            "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
  Get-ItemProperty $chaves -ErrorAction SilentlyContinue |
    Where-Object { $_.DisplayName -like $padrao -and ($_.UninstallString -or $_.QuietUninstallString) }
}

function Escolher($lista, $titulo, $marcar) {
  Write-Host "`n=== $titulo ===" -ForegroundColor Cyan
  for ($n = 0; $n -lt $lista.Count; $n++) {
    $extra = ""
    if ($marcar -and (Get-Instalado $lista[$n][3])) { $extra = "  (instalado)" }
    Write-Host ("  [{0}] {1}{2}" -f ($n + 1), $lista[$n][0], $extra)
  }
  Write-Host "  [T] Todos"
  Write-Host "  [0] Voltar/Sair"
  Write-Host "`nDigite os numeros separados por virgula ou espaco (ex: 1,3,5) ou T para todos."
  $sel = Read-Host "Escolha"

  if ($sel -match '^\s*(0|s|sair)?\s*$') { return @() }
  if ($sel -match '^\s*(t|todos|all)\s*$') { return $lista }

  $idx = @($sel -split '[,\s;]+' | Where-Object { $_ -match '^\d+$' } | ForEach-Object { [int]$_ } |
           Where-Object { $_ -ge 1 -and $_ -le $lista.Count } | Sort-Object -Unique)
  if ($idx.Count -eq 0) { Write-Host "Selecao invalida." -ForegroundColor Red; return @() }
  return @($idx | ForEach-Object { ,$lista[$_ - 1] })
}

Write-Host "`n=== DLTechSup - Instaladores ===" -ForegroundColor Cyan
Write-Host "  [1] Instalar programas"
Write-Host "  [2] Remover programas"
Write-Host "  [0] Sair"
$modo = (Read-Host "Escolha").Trim()

if ($modo -eq "2") {
  $admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
  if (-not $admin) { Write-Host "Aviso: abra o PowerShell como Administrador para remover programas." -ForegroundColor Yellow }

  $sel = @(Escolher $apps "Remover programas" $true)
  if ($sel.Count -eq 0) { Write-Host "Nada selecionado. Saindo."; return }

  $i = 0
  foreach ($a in $sel) {
    $i++
    Write-Host "[$i/$($sel.Count)] Removendo $($a[0])... " -NoNewline
    $achados = @(Get-Instalado $a[3])
    if ($achados.Count -eq 0) { Write-Host "Nao encontrado" -ForegroundColor Yellow; continue }
    foreach ($p in $achados) {
      try {
        if ($p.QuietUninstallString) {
          $cmd = $p.QuietUninstallString
        } elseif ($p.UninstallString -match 'msiexec') {
          $cmd = ($p.UninstallString -replace '/I', '/X') + " /qn /norestart"
        } else {
          $cmd = "$($p.UninstallString) $($a[4])"
        }
        Start-Process cmd.exe -ArgumentList "/c `"$cmd`"" -Wait -WindowStyle Hidden
        Write-Host "Concluido" -ForegroundColor Green
      } catch {
        Write-Host "Falhou: $($_.Exception.Message)" -ForegroundColor Red
      }
    }
  }
  Write-Host "`nRemocoes finalizadas." -ForegroundColor Cyan
  return
}

if ($modo -ne "1") { Write-Host "Saindo."; return }

$apps = @(Escolher $apps "Instalar programas" $false)
if ($apps.Count -eq 0) { Write-Host "Nada selecionado. Saindo."; return }

New-Item $tmp -ItemType Directory -Force | Out-Null
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
