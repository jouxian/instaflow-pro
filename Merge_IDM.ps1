# InstaFlow Pro: manual, lossless joining of IDM video + audio downloads.
param([Parameter(Mandatory=$true)][string]$Folder)
$ErrorActionPreference='Stop'
try {
  $ff=Get-Command 'ffmpeg.exe' -ErrorAction SilentlyContinue
  if(-not $ff){throw 'FFmpeg not found. Reopen this window after installing FFmpeg.'}
  if(-not (Test-Path -LiteralPath $Folder -PathType Container)){throw 'Download folder not found.'}
  $v=@(Get-ChildItem -LiteralPath $Folder -File -ErrorAction Stop | Where-Object {$_.Name -match '^InstaFlow_video\.(mp4|webm|mkv|mov)$'})
  $a=@(Get-ChildItem -LiteralPath $Folder -File -ErrorAction Stop | Where-Object {$_.Name -match '^InstaFlow_audio\.(m4a|webm|mp4|opus|ogg|mp3)$'})
  if($v.Count -ne 1 -or $a.Count -ne 1){throw 'Both the complete InstaFlow_video and InstaFlow_audio files must exist in this folder. Finish both IDM downloads first.'}
  $target=Join-Path $Folder 'InstaFlow_merged.mkv'
  Write-Host 'Merging downloaded video and audio without re-encoding...' -ForegroundColor Cyan
  & $ff.Source -nostdin -hide_banner -loglevel warning -y -i $v[0].FullName -i $a[0].FullName -map '0:v:0' -map '1:a:0' -c copy $target
  if($LASTEXITCODE -ne 0 -or -not(Test-Path -LiteralPath $target)){throw 'Merge failed. Verify downloads are complete and playable.'}
  Write-Host ('DONE: '+$target) -ForegroundColor Green
  Write-Host 'Original video and audio files were preserved.' -ForegroundColor Green
} catch {
  Write-Host ('ERROR: '+$_.Exception.Message) -ForegroundColor Red
  exit 1
}
