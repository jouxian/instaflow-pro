# InstaFlow Pro v2.6 setup. Installs files under the current user's local app directory.
$ErrorActionPreference='Stop'
$dest=Join-Path $env:LOCALAPPDATA 'InstaFlow'
try {
    New-Item -ItemType Directory -Force -Path $dest | Out-Null
    $files=@('InstaFlow.ps1','Worker.ps1','Ensure_Tools.ps1','InstaFlow.ico','Open_InstaFlow.vbs','Open_InstaFlow.bat','README.md','GUIDE.md','Update_Tools.bat','Merge_IDM.ps1')
    foreach($name in $files) {
        $source=Join-Path $PSScriptRoot $name
        if(Test-Path -LiteralPath $source) { Copy-Item -LiteralPath $source -Destination (Join-Path $dest $name) -Force }
    }
    Write-Host '[1/3] Application files copied.' -ForegroundColor Green

    Write-Host '[2/3] Preparing runtime tools. The first setup may take a few minutes...' -ForegroundColor Cyan
    $bootstrap=Join-Path $dest 'Ensure_Tools.ps1'
    if(-not (Test-Path -LiteralPath $bootstrap)) { throw 'Ensure_Tools.ps1 is missing from the package.' }
    & powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File $bootstrap
    if($LASTEXITCODE -ne 0) { throw 'One or more required runtime tools could not be prepared.' }

    $desktop=[Environment]::GetFolderPath('Desktop')
    $shell=New-Object -ComObject WScript.Shell
    $lnk=$shell.CreateShortcut((Join-Path $desktop 'InstaFlow Pro.lnk'))
    $lnk.TargetPath=(Join-Path $env:WINDIR 'System32\wscript.exe')
    $lnk.Arguments=('//B "'+(Join-Path $dest 'Open_InstaFlow.vbs')+'"')
    $lnk.WorkingDirectory=$dest
    $lnk.IconLocation=((Join-Path $dest 'InstaFlow.ico')+',0')
    $lnk.Description='InstaFlow Pro - Instagram and YouTube downloader'
    $lnk.Save()

    $legacyLink=Join-Path $desktop 'InstaFlow.lnk'
    if (Test-Path -LiteralPath $legacyLink) {
        $old=$shell.CreateShortcut($legacyLink)
        $old.TargetPath=$lnk.TargetPath
        $old.Arguments=$lnk.Arguments
        $old.WorkingDirectory=$dest
        $old.IconLocation=((Join-Path $dest 'InstaFlow.ico')+',0')
        $old.Save()
    }

    Write-Host '[3/3] InstaFlow Pro desktop shortcut is ready.' -ForegroundColor Green
    Write-Host ''
    Write-Host 'Setup completed successfully.' -ForegroundColor Green
    Start-Process -FilePath 'wscript.exe' -ArgumentList ('//B "'+(Join-Path $dest 'Open_InstaFlow.vbs')+'"')
} catch {
    Write-Host ('INSTALL ERROR: '+$_.Exception.Message) -ForegroundColor Red
    Read-Host 'Press Enter to close'
    exit 1
}

