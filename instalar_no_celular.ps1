# Script de Instalação Automática via USB (ADB)
$adb = "$env:USERPROFILE\platform-tools\adb.exe"

if (-not (Test-Path $adb)) {
    Write-Host "ADB não encontrado. Baixando platform-tools..." -ForegroundColor Yellow
    Invoke-WebRequest -Uri 'https://dl.google.com/android/repository/platform-tools-latest-windows.zip' -OutFile "$env:TEMP\platform-tools.zip"
    Expand-Archive -Path "$env:TEMP\platform-tools.zip" -DestinationPath "$env:USERPROFILE" -Force
}

Write-Host "Verificando celular conectado via USB..." -ForegroundColor Cyan
$devices = & $adb devices
$deviceLines = $devices | Where-Object { $_ -match "\bdevice\b" -and $_ -notmatch "List of" }

if (-not $deviceLines) {
    Write-Host "Nenhum celular detectado via USB com Depuração ativada." -ForegroundColor Red
    Write-Host "Certifique-se de que a Depuração USB está ativa e confirme a permissão na tela do celular." -ForegroundColor Yellow
    exit 1
}

Write-Host "Celular detectado com sucesso!" -ForegroundColor Green

$apkUrl = "https://github.com/mayconmiguel13/coletor-patrimonio/releases/download/latest/app-release.apk"
$destApk = "$env:TEMP\app-release.apk"

Write-Host "Baixando o APK mais recente diretamente da Release..." -ForegroundColor Cyan
try {
    Invoke-WebRequest -Uri $apkUrl -OutFile $destApk
} catch {
    Write-Host "Aguarde a conclusão da compilação no GitHub para que o APK esteja disponível para download." -ForegroundColor Yellow
    exit 1
}

Write-Host "Instalando APK no celular..." -ForegroundColor Cyan
& $adb install -r $destApk

Write-Host "Abrindo aplicativo no celular..." -ForegroundColor Green
& $adb shell am start -n com.coletor.coletor_patrimonio/.MainActivity

Write-Host "Concluído! O app foi instalado e aberto no celular." -ForegroundColor Green
