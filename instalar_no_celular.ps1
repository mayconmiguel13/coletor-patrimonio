# Script de Instalação Rápida via USB (ADB)
$adb = "$env:USERPROFILE\platform-tools\adb.exe"

if (-not (Test-Path $adb)) {
    Write-Host "Baixando ferramentas ADB..." -ForegroundColor Yellow
    Invoke-WebRequest -Uri 'https://dl.google.com/android/repository/platform-tools-latest-windows.zip' -OutFile "$env:TEMP\platform-tools.zip"
    Expand-Archive -Path "$env:TEMP\platform-tools.zip" -DestinationPath "$env:USERPROFILE" -Force
}

Write-Host "Verificando celular conectado via USB..." -ForegroundColor Cyan
$devices = & $adb devices
$deviceLines = $devices | Where-Object { $_ -match "\bdevice\b" -and $_ -notmatch "List of" }

if (-not $deviceLines) {
    Write-Host "Nenhum celular detectado via USB. Verifique se o cabo está conectado e a Depuração USB ativada." -ForegroundColor Red
    exit 1
}

Write-Host "Celular detectado!" -ForegroundColor Green

# 1. Baixar o APK mais recente da Release
$apkUrl = "https://github.com/mayconmiguel13/coletor-patrimonio/releases/download/latest/app-release.apk"
$destApk = "$PSScriptRoot\app-release.apk"

Write-Host "Baixando o APK mais recente..." -ForegroundColor Cyan
try {
    Invoke-WebRequest -Uri $apkUrl -OutFile $destApk
} catch {
    Write-Host "Aviso: Usando versão local já existente." -ForegroundColor Yellow
}

# 2. Envia direto para a pasta Downloads do celular em 1 segundo
Write-Host "Enviando APK para a pasta Downloads do celular..." -ForegroundColor Cyan
& $adb push $destApk "/sdcard/Download/coletor-patrimonio.apk"
Write-Host "-> APK copiado para o celular em: Downloads/coletor-patrimonio.apk" -ForegroundColor Green

# 3. Tenta instalar diretamente via ADB
Write-Host "Instalando automaticamente..." -ForegroundColor Cyan
$installResult = & $adb install -r $destApk 2>&1

if ($installResult -match "Success") {
    Write-Host "Instalação concluída com sucesso!" -ForegroundColor Green
    & $adb shell am start -n com.coletor.coletor_patrimonio/.MainActivity
} else {
    Write-Host "Dica Xiaomi: Ative a opção 'Instalar via USB' nas Opções do Desenvolvedor para instalação direta." -ForegroundColor Yellow
    Write-Host "Ou abra o arquivo 'coletor-patrimonio.apk' na pasta Downloads do seu celular para instalar agora." -ForegroundColor Cyan
}
