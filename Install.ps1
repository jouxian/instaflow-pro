# InstaFlow Pro setup. Installs files under current user's local app directory.
$ErrorActionPreference='Stop'
$dest=Join-Path $env:LOCALAPPDATA 'InstaFlow'
try {
    New-Item -ItemType Directory -Force -Path $dest | Out-Null
    foreach($name in @('InstaFlow.ps1','Worker.ps1','InstaFlow.ico','Open_InstaFlow.vbs','Open_InstaFlow.bat','README.txt','GUIDE_FA.txt','Update_Tools.bat','Merge_IDM.ps1')) {
        Copy-Item -LiteralPath (Join-Path $PSScriptRoot $name) -Destination (Join-Path $dest $name) -Force
    }
    Write-Host '[1/3] Application files copied.' -ForegroundColor Green
    $globalGallery=Get-Command 'gallery-dl.exe' -ErrorAction SilentlyContinue
    $localGallery=Join-Path $dest 'gallery-dl.exe'
    if (-not $globalGallery -and -not(Test-Path -LiteralPath $localGallery)) {
        Write-Host '[2/3] Downloading optional gallery-dl from its official release...' -ForegroundColor Cyan
        $sources=@(
            'https://github.com/mikf/gallery-dl/releases/latest/download/gallery-dl.exe',
            'https://codeberg.org/mikf/gallery-dl/releases/download/v1.32.12/gallery-dl.exe'
        )
        $installed=$false
        foreach($url in $sources) {
            $tmp=Join-Path $env:TEMP ('gallery-dl-'+[Guid]::NewGuid().ToString('N')+'.exe')
            try {
                [Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12
                Invoke-WebRequest -Uri $url -OutFile $tmp -UseBasicParsing -TimeoutSec 65 -MaximumRedirection 6
                if ((Get-Item $tmp).Length -gt 400000) {
                    Move-Item -LiteralPath $tmp -Destination $localGallery -Force
                    Write-Host 'gallery-dl downloaded successfully (source: official release).' -ForegroundColor Green
                    $installed=$true
                    break
                }
            } catch { Write-Host ('Mirror unavailable: '+$_.Exception.Message) -ForegroundColor DarkYellow }
            finally { if(Test-Path -LiteralPath $tmp){Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue} }
        }
        if(-not $installed) {
            Write-Host 'Warning: gallery-dl could not be downloaded; Instagram albums and avatars need it.' -ForegroundColor Yellow
            Write-Host 'You can manually download gallery-dl.exe from https://codeberg.org/mikf/gallery-dl/releases and copy it into:' -ForegroundColor Yellow
            Write-Host $dest -ForegroundColor Yellow
        }
    } else {Write-Host '[2/3] gallery-dl available.' -ForegroundColor Green}
    # Optional acceleration engine (winget official package). No credential handling.
    try {
        $env:Path = [Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [Environment]::GetEnvironmentVariable('Path','User')
        $aria=Get-Command 'aria2c.exe' -ErrorAction SilentlyContinue
        if(-not $aria) {
            $winget=Get-Command 'winget.exe' -ErrorAction SilentlyContinue
            if($winget) {
                Write-Host 'Installing optional aria2 accelerator (official winget package)...' -ForegroundColor Cyan
                & $winget.Source install --id aria2.aria2 --exact --accept-package-agreements --accept-source-agreements
                if($LASTEXITCODE -ne 0) { Write-Host 'aria2 installation unavailable: native download remains enabled.' -ForegroundColor Yellow }
            } else { Write-Host 'winget not found: optional aria2 unavailable. Normal downloads still work.' -ForegroundColor Yellow }
        } else { Write-Host 'aria2 accelerator found.' -ForegroundColor Green }
    } catch { Write-Host ('Optional aria2 setup skipped: '+$_.Exception.Message) -ForegroundColor Yellow }
    $desktop=[Environment]::GetFolderPath('Desktop')
    $shell=New-Object -ComObject WScript.Shell
    $lnk=$shell.CreateShortcut((Join-Path $desktop 'InstaFlow Pro.lnk'))
    $lnk.TargetPath=(Join-Path $env:WINDIR 'System32\wscript.exe')
    $lnk.Arguments=('//B "'+(Join-Path $dest 'Open_InstaFlow.vbs')+'"')
    $lnk.WorkingDirectory=$dest
    $lnk.IconLocation=((Join-Path $dest 'InstaFlow.ico')+',0')
    $lnk.Description='InstaFlow Pro - Instagram photos, albums, profile pictures and YouTube videos'
    $lnk.Save()
    # Also repoint the previous version's desktop shortcut, when present.
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
    Write-Host 'You can now double-click InstaFlow Pro on the desktop.' -ForegroundColor Green
    Start-Process -FilePath 'wscript.exe' -ArgumentList ('//B "'+(Join-Path $dest 'Open_InstaFlow.vbs')+'"')
} catch {
    Write-Host ('INSTALL ERROR: '+$_.Exception.Message) -ForegroundColor Red
    Read-Host 'Press Enter to close'
    exit 1
}
