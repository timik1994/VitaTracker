# PowerShell-скрипт для сборки релизного APK и переименования
flutter build apk --release

$apkPath = "build/app/outputs/flutter-apk/app-release.apk"
$destPath = "build/app/outputs/flutter-apk/VitaTracker.apk"

if (Test-Path $apkPath) {
    Rename-Item -Path $apkPath -NewName "VitaTracker.apk"
    Write-Host "APK успешно переименован: VitaTracker.apk"
} else {
    Write-Host "APK не найден по пути $apkPath"
} 