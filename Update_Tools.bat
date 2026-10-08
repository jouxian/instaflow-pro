@echo off
chcp 65001 > nul
echo Updating yt-dlp and ffmpeg if winget supports them...
winget upgrade -e --id yt-dlp.yt-dlp --accept-package-agreements --accept-source-agreements
winget upgrade -e --id Gyan.FFmpeg --accept-package-agreements --accept-source-agreements
echo Installing / updating aria2c accelerator...
winget install -e --id aria2.aria2 --accept-package-agreements --accept-source-agreements
pause
