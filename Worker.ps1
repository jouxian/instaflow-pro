# InstaFlow Pro background worker - Windows PowerShell 5.1
param([Parameter(Mandatory=$true)][string]$JobFile)
$ErrorActionPreference='Continue'
$ProgressPreference='SilentlyContinue'
try { [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false) } catch {}
$job = Get-Content -LiteralPath $JobFile -Raw -Encoding UTF8 | ConvertFrom-Json
if ([string]$job.browser -notin @('firefox','chrome','edge')) { $job.browser='firefox' }
$work = [string]$job.work
$log = Join-Path $work 'worker.log'
$resultFile = Join-Path $work 'result.json'
$statusFile = Join-Path $work 'status.json'
function State([string]$message, [int]$percent=0) {
    try {
        @{ message=$message; percent=$percent } | ConvertTo-Json -Compress | Set-Content -LiteralPath $statusFile -Encoding UTF8
    } catch {}
}
function Result([object]$data) {
    $data | ConvertTo-Json -Depth 18 -Compress | Set-Content -LiteralPath $resultFile -Encoding UTF8
}
function Fail([string]$message) {
    State 'Error' 0
    Result @{ ok=$false; message=$message; items=@() }
    exit 1
}
$localTools = Join-Path $PSScriptRoot 'tools'
try {
    $env:Path = $localTools + ';' + [Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [Environment]::GetEnvironmentVariable('Path','User')
} catch { $env:Path = $localTools + ';' + $env:Path }
function Tool([string]$name) {
    foreach($local in @((Join-Path $PSScriptRoot $name),(Join-Path $localTools $name))) {
        if (Test-Path -LiteralPath $local) { return $local }
    }
    $command = Get-Command $name -ErrorAction SilentlyContinue
    if ($command) { return $command.Source }
    return $null
}
function Pick([object]$obj, [string[]]$keys) {
    foreach ($key in $keys) {
        if ($null -ne $obj -and $null -ne $obj.PSObject.Properties[$key]) {
            $v = $obj.$key
            if ($null -ne $v -and [string]$v -ne '') { return $v }
        }
    }
    return $null
}
function CollectMessages([object]$node, [System.Collections.ArrayList]$accumulator) {
    if ($null -eq $node -or $node -isnot [array]) { return }
    if ($node.Length -ge 2 -and $node[0] -is [ValueType] -and [string]$node[0] -in @('2','3','6')) {
        [void]$accumulator.Add($node)
        return
    }
    foreach ($child in $node) { CollectMessages $child $accumulator }
}
# Launch external scanners with a hard time limit. No endless 18% progress on HTTP 429.
function QuoteArg([string]$text) {
    if ($text -eq '') { return '""' }
    if ($text -notmatch '[\s"]') { return $text }
    $escaped = $text -replace '(\\*)"', '$1$1\"'
    $escaped = $escaped -replace '(\\+)$', '$1$1'
    return '"' + $escaped + '"'
}
function RunBounded([string]$exe, [string[]]$arguments, [string]$stdout, [string]$stderr, [int]$seconds) {
    $formatted = @(foreach($a in $arguments) { QuoteArg ([string]$a) }) -join ' '
    try {
        $proc = Start-Process -FilePath $exe -ArgumentList $formatted -PassThru -WindowStyle Hidden -RedirectStandardOutput $stdout -RedirectStandardError $stderr -ErrorAction Stop
    } catch {
        ("Could not start: " + $_.Exception.Message) | Out-File -LiteralPath $stderr -Encoding UTF8
        return 127
    }
    try {
        $finished = $proc.WaitForExit([int]($seconds * 1000))
        if (-not $finished) {
            try { & taskkill.exe /T /F /PID $proc.Id *> $null } catch { try {$proc.Kill()} catch {} }
            $script:timedOut = $true
            ("Timed out after " + $seconds + " seconds") | Out-File -LiteralPath $stderr -Append -Encoding UTF8
            return 124
        }
        return [int]$proc.ExitCode
    } finally { try {$proc.Dispose()} catch {} }
}
function IDMPath {
    $candidates=New-Object System.Collections.ArrayList
    $cmd=Get-Command 'IDMan.exe' -ErrorAction SilentlyContinue
    if($cmd){[void]$candidates.Add($cmd.Source)}
    foreach($registry in @('HKCU:\Software\Microsoft\Windows\CurrentVersion\App Paths\IDMan.exe','HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\IDMan.exe','HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\App Paths\IDMan.exe')) {
        try {$r=Get-Item -LiteralPath $registry -ErrorAction Stop; $value=$r.GetValue(''); if($value){[void]$candidates.Add([string]$value)}}catch{}
    }
    foreach($base in @(${env:ProgramFiles(x86)},$env:ProgramFiles)) {
        if($base) {[void]$candidates.Add((Join-Path $base 'Internet Download Manager\IDMan.exe'))}
    }
    foreach($candidate in $candidates){if(Test-Path -LiteralPath $candidate){return $candidate}}
    return $null
}
function MediaName([string]$name,[string]$extension,[int]$counter) {
    $safe=[regex]::Replace($name,'[\\/:*?"<>|\x00-\x1f]','_')
    if($safe.Length -gt 75){$safe=$safe.Substring(0,75)}
    if(-not $safe){$safe='Media'}
    return ('InstaFlow_'+$counter+'_'+$safe+'.'+$extension)
}
# Extract the actual, current CDN file URLs for precisely the quality selected in the GUI.
# These URLs are short-lived and MUST NOT be reused or logged to a persistent file.
function DirectFormatsFromYt([string]$page,[string]$yt,[string]$quality) {
    $json=Join-Path $work ('stream_'+[Guid]::NewGuid().ToString('N')+'.json')
    $err=Join-Path $work 'direct.err'
    $audioOnly=$quality -like 'audio_*'
    if($audioOnly){$selector='ba[ext=m4a]/ba'}
    elseif($quality -match '^(2160|1440|1080|720)$'){$selector='bv[height<='+$quality+']+ba/b[height<='+$quality+']'}
    else{$selector='bv+ba/b'}

    # Public media should work without any browser login.
    # Browser cookies are used only as a fallback for content that actually requires them.
    $baseArgs=@('--force-ipv4','--no-playlist','--no-warnings','--socket-timeout','15','--retries','1','--extractor-retries','1','-f',$selector,'--dump-single-json','--',$page)
    $script:timedOut=$false
    $code=RunBounded $yt $baseArgs $json $err 45

    if($code -ne 0 -and [string]$job.browser -in @('firefox','chrome','edge')){
        Remove-Item -LiteralPath $json -Force -ErrorAction SilentlyContinue
        ('Public access failed; retrying with '+[string]$job.browser+' browser cookies.') | Out-File -LiteralPath $err -Append -Encoding UTF8
        $cookieArgs=@('--cookies-from-browser',([string]$job.browser)) + $baseArgs
        $script:timedOut=$false
        $code=RunBounded $yt $cookieArgs $json $err 45
    }

    if($code -ne 0){Remove-Item -LiteralPath $json -Force -ErrorAction SilentlyContinue;return @()}
    try {
        $meta=Get-Content -LiteralPath $json -Raw -Encoding UTF8 -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
        $formats=if($null -ne $meta.requested_formats -and @($meta.requested_formats).Count -gt 0){@($meta.requested_formats)}else{@($meta)}
        $files=New-Object System.Collections.ArrayList
        foreach($fmt in $formats){
            $u=[string]$fmt.url
            $protocol=[string]$fmt.protocol
            if($u -notmatch '^https?://' -or $protocol -match 'm3u8|dash|rtmp|ism|f4m' -or $u -match '\.(?:m3u8|mpd)(?:\?|$)'){continue}
            $v=[string]$fmt.vcodec
            $a=[string]$fmt.acodec
            $role=if($v -and $v -ne 'none' -and $a -and $a -ne 'none'){'combined'}elseif($v -and $v -ne 'none'){'video'}elseif($a -and $a -ne 'none'){'audio'}else{'unknown'}
            $extension=[string]$fmt.ext
            if($extension -notmatch '^[a-zA-Z0-9]{2,5}$'){$extension=if($role -eq 'audio'){'m4a'}else{'mp4'}}
            [void]$files.Add([pscustomobject]@{url=$u;role=$role;ext=$extension;formatId=[string]$fmt.format_id;height=[string]$fmt.height})
        }
        return $files.ToArray()
    } catch {return @()}
    finally {
        Remove-Item -LiteralPath $json -Force -ErrorAction SilentlyContinue
    }
}
function SubmitIDM([string]$idm,[string]$source,[string]$folder,[string]$file) {
    # Official IDM CLI: /d supplies the DIRECT CDN URL; /p and /f name the output.
    $arguments=@('/d',$source,'/p',$folder,'/f',$file)
    $formatted=@(foreach($part in $arguments){QuoteArg ([string]$part)}) -join ' '
    Start-Process -FilePath $idm -ArgumentList $formatted -ErrorAction Stop | Out-Null
}
function PrepareMergeShortcut([string]$folder) {
    # This helper runs ONLY when the user chooses it after BOTH IDM downloads finish.
    $content="@echo off`r`nchcp 65001 >nul`r`npowershell.exe -NoProfile -ExecutionPolicy Bypass -File `"%LOCALAPPDATA%\InstaFlow\Merge_IDM.ps1`" -Folder `"%~dp0.`"`r`npause`r`n"
    $file=Join-Path $folder 'Merge_IDM.cmd'
    [System.IO.File]::WriteAllText($file,$content,[System.Text.Encoding]::ASCII)
}
function GalleryItems([string]$url, [string]$gallery) {
    $out = Join-Path $work 'gallery.json'
    $err = Join-Path $work 'gallery.err'
    $browser=[string]$job.browser
    if (-not $browser) {$browser='firefox'}
    # gallery-dl -j emits one multi-line JSON array of message records.
    # Message code 2 is directory metadata; code 3 is an individual media URL.
    $script:timedOut=$false
    $limit=if($url -match '/avatar/?(?:[?]|$)'){35}else{85}
    $args=@('--cookies-from-browser',$browser,'--no-input','--retries','0','--dump-json')
    if($url -match '/avatar/?(?:[?]|$)') {$args+=@('-o','extractor.instagram.user-strategy=web,search')}
    $args+=@('--',$url)
    $scanCode=RunBounded $gallery $args $out $err $limit
    if($scanCode -eq 124){$script:scanFailure='Instagram response took more than '+$limit+' seconds. A temporary rate limit or HTTP 429 may be active. Try again later.';return @()}

    $raw = Get-Content -LiteralPath $out -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
    $nodes=New-Object System.Collections.ArrayList
    try {
        $decoded=ConvertFrom-Json -InputObject $raw -ErrorAction Stop
        CollectMessages $decoded $nodes
    } catch {
        # Some versions write a JSON object per line; handle those, too.
        foreach ($line in @(Get-Content -LiteralPath $out -Encoding UTF8 -ErrorAction SilentlyContinue)) {
            try { CollectMessages (ConvertFrom-Json -InputObject $line -ErrorAction Stop) $nodes } catch {}
        }
    }
    $list = New-Object System.Collections.ArrayList
    $index = 0
    foreach ($entry in $nodes) {
        if ($entry.Count -lt 3 -or [string]$entry[0] -ne '3') { continue }
        $remote=[string]$entry[1]
        if ($remote -notmatch '^https?://' -and $remote -notmatch '^ytdl:') { continue }
        $m=$entry[2]
        $index++
        $ext=[string](Pick $m @('extension','ext'))
        if (-not $ext -and $remote -match '\.(jpg|jpeg|png|webp|mp4|m4v)(?:\?|$)') { $ext=$Matches[1] }
        $videoFlag=[string](Pick $m @('is_video','media_type','type'))
        $isVideo=($remote -match '^ytdl:' -or $ext -match '^(mp4|m4v|webm|mov)$' -or $videoFlag -in @('True','2','video'))
        $thumb=[string](Pick $m @('thumbnail','thumbnail_url','display_url','display_src','preview_url','image_url','cover_url'))
        if (-not $thumb -and -not $isVideo) { $thumb=$remote }
        if (-not $thumb -and $m.image_versions2 -and $m.image_versions2.candidates) { $thumb=[string]$m.image_versions2.candidates[0].url }
        $kind=if ($isVideo) {'Video'} else {'Image'}
        [void]$list.Add(@{ index=$index; kind=$kind; title=($kind+' '+$index); thumb=$thumb; url=$remote; selectIndex=$index; downloadUrl=$url; engine='gallery' })
    }
    return $list.ToArray()
}
function YtdlpItems([string]$url, [string]$yt) {
    $out = Join-Path $work 'yt.json'
    $err = Join-Path $work 'yt.err'

    # First try public access with no browser cookies.
    $baseArgs=@('--force-ipv4','--flat-playlist','--playlist-end','60','--dump-single-json','--no-warnings','--socket-timeout','15','--retries','1','--extractor-retries','1','--',$url)
    $script:timedOut=$false
    $scanCode=RunBounded $yt $baseArgs $out $err 45

    # Retry with browser cookies only if public access fails.
    if($scanCode -ne 0 -and [string]$job.browser -in @('firefox','chrome','edge')){
        Remove-Item -LiteralPath $out -Force -ErrorAction SilentlyContinue
        ('Public access failed; retrying with '+[string]$job.browser+' browser cookies.') | Out-File -LiteralPath $err -Append -Encoding UTF8
        State ('Public access failed. Retrying with '+[string]$job.browser+' cookies...') 32
        $cookieArgs=@('--cookies-from-browser',([string]$job.browser)) + $baseArgs
        $script:timedOut=$false
        $scanCode=RunBounded $yt $cookieArgs $out $err 45
    }

    if($scanCode -eq 124){$script:scanFailure='The YouTube request timed out. Public access was attempted first; browser cookies were used only as a fallback.';return @()}
    if($scanCode -ne 0){return @()}

    $data = $null
    try { $data = Get-Content -LiteralPath $out -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop } catch { return @() }
    $entries = @()
    if ($null -ne $data.entries -and @($data.entries).Count -gt 0) { $entries=@($data.entries) }
    else { $entries=@($data) }
    $items = New-Object System.Collections.ArrayList
    $number=0
    foreach ($e in $entries) {
        if ($null -eq $e) { continue }
        $number++
        $vid = [string](Pick $e @('webpage_url','original_url','url'))
        $id = [string](Pick $e @('id'))
        $isYouTube = $url -match '(?i)youtu\.be|youtube\.com'
        if ($isYouTube -and $id -match '^[a-zA-Z0-9_-]{11}$') { $vid='https://www.youtube.com/watch?v='+$id }
        if (-not $vid -or $vid -notmatch '^https?://') { $vid=$url }
        $thumb = [string](Pick $e @('thumbnail'))
        if (-not $thumb -and $e.thumbnails -and @($e.thumbnails).Count -gt 0) {
            $thumb = [string]$e.thumbnails[@($e.thumbnails).Count-1].url
        }
        if (-not $thumb -and $isYouTube -and $id) { $thumb='https://i.ytimg.com/vi/'+$id+'/hqdefault.jpg' }
        $title=[string](Pick $e @('title','fulltitle','description'))
        if (-not $title) { $title='Video '+$number }
        $kind='Video'
        if ([string](Pick $e @('ext')) -match '^(jpg|png|webp)$') { $kind='Image' }
        [void]$items.Add(@{index=$number; kind=$kind; title=$title; thumb=$thumb; url=$vid; downloadUrl=$url; selectIndex=$number; engine='yt' })
    }
    return $items.ToArray()
}
function ReadLastError([string]$fallback) {
    if($script:scanFailure){return $script:scanFailure}
    foreach ($file in @((Join-Path $work 'gallery.err'),(Join-Path $work 'yt.err'),$log)) {
        if (Test-Path -LiteralPath $file) {
            $tail = @(Get-Content -LiteralPath $file -Tail 10 -ErrorAction SilentlyContinue | Where-Object { $_ -match 'error|ERROR|429|403|private|failed|not found' })
            if ($tail.Count -gt 0) {
                $message=([string]$tail[-1]).Trim()
                if($message -match '429'){return 'Instagram is temporarily rate-limiting profile picture requests (HTTP 429). Wait a while before trying again.'}
                return $message
            }
        }
    }
    return $fallback
}
try {
    $url=[string]$job.url
    $yt=Tool 'yt-dlp.exe'
    $gallery=Tool 'gallery-dl.exe'
    if ([string]$job.mode -eq 'scan') {
        State 'Scanning the link and building the media list...' 8
        $isIG = $url -match '^https?://(?:www\.)?instagram\.com/'
        $isProfile = $isIG -and $url -match '^https?://(?:www\.)?instagram\.com/([A-Za-z0-9._]+)/?(?:\?.*)?$' -and $Matches[1] -notin @('p','reel','reels','stories','explore','direct','accounts')
        if ($isProfile) {
            if (-not $gallery) { Fail 'gallery-dl is required for profile pictures. Run Install.bat again.' }
            $user = $Matches[1]
            State 'Finding the profile picture...' 18
            $items = @(GalleryItems ('https://www.instagram.com/'+$user+'/avatar/') $gallery)
            if ($items.Count -eq 0) { Fail (ReadLastError 'The profile picture could not be retrieved. Instagram may be restricting access.') }
            Result @{ok=$true; items=$items; source='profile'; message='The profile picture is ready to select.'}
            exit 0
        }
        if ($isIG -and $gallery -and $url -notmatch '/(?:stories|reel)/') {
            $items=@(GalleryItems $url $gallery)
            if ($items.Count -gt 0) {
                if ($items.Count -eq 1 -and $items[0].kind -eq 'Video' -and $url -match '/p/') {
                    # yt-dlp generally merges video/audio better for standalone clips.
                    $items[0].engine='yt'
                    $items[0].url=$url
                }
                Result @{ok=$true; items=$items; source='instagram'; message=('Found '+$items.Count+' images/videos.')}
                exit 0
            }
        }
        if (-not $yt) { Fail 'yt-dlp was not found. Run Install.bat or place yt-dlp.exe next to Worker.ps1.' }
        State 'Reading video information...' 40
        $items=@(YtdlpItems $url $yt)
        if ($items.Count -lt 1) { Fail (ReadLastError 'No media was found. Public access was tried first; browser cookies are only a fallback for restricted content.') }
        $note=('Found '+$items.Count+' items.')
        if($url -match '(youtube\.com|youtu\.be)' -and -not (Tool 'deno.exe')) {
            $note+=' For broader access to YouTube formats, run Update_Tools.bat to install Deno.'
        }
        Result @{ok=$true; items=$items; source='video'; message=$note}
        exit 0
    }
    if ([string]$job.mode -eq 'idm') {
        $idm=IDMPath
        if(-not $idm){Fail 'IDM (IDMan.exe) was not found. Install IDM first.'}
        $selected=@($job.items)
        if($selected.Count -eq 0){Fail 'No files are selected.'}
        $destination=[string]$job.output
        if(-not (Test-Path -LiteralPath $destination)){New-Item -Path $destination -ItemType Directory -Force|Out-Null}
        $sent=0
        $mergeTasks=0
        $errors=New-Object System.Collections.ArrayList
        $counter=0
        foreach($item in $selected){
            $counter++
            State ('Extracting direct media URL, item '+$counter+' of '+$selected.Count) ([int](5+85*$counter/[Math]::Max(1,$selected.Count)))
            $streams=@()
            if([string]$item.engine -eq 'gallery' -and [string]$item.url -match '^https?://') {
                $address=[string]$item.url
                $extension='mp4'
                if(([Uri]$address).AbsolutePath -match '\.(jpg|jpeg|png|webp|gif|mp4|mov|m4v)$'){$extension=$Matches[1]}
                elseif([string]$item.kind -eq 'Image'){$extension='jpg'}
                $streams=@([pscustomobject]@{url=$address;role='combined';ext=$extension})
            } elseif ([string]$item.engine -eq 'yt') {
                if(-not $yt){[void]$errors.Add('yt-dlp was not found.');continue}
                $streams=@(DirectFormatsFromYt ([string]$item.url) $yt ([string]$job.quality))
            }
            if($streams.Count -eq 0){
                [void]$errors.Add('Item '+$counter+': no direct media URL was found. Use the built-in downloader for HLS/DASH or restricted links.')
                continue
            }
            # Video-only + audio-only streams are two DISTINCT IDM downloads.
            $separate=($streams.Count -eq 2 -and @($streams | Where-Object {$_.role -eq 'video'}).Count -eq 1 -and @($streams | Where-Object {$_.role -eq 'audio'}).Count -eq 1)
            if($streams.Count -gt 1 -and -not $separate){
                [void]$errors.Add('Item '+$counter+': this source stream combination is not supported.')
                continue
            }
            $folder=$destination
            if($separate){
                $safe=[regex]::Replace([string]$item.title,'[\\/:*?"<>|\x00-\x1f]','_')
                if($safe.Length -gt 42){$safe=$safe.Substring(0,42)}
                if(-not $safe){$safe='Video'}
                $folder=Join-Path $destination ('InstaFlow_IDM_'+$counter+'_'+$safe+'_'+[Guid]::NewGuid().ToString('N').Substring(0,6))
                New-Item -ItemType Directory -Path $folder -Force|Out-Null
            }
            $submitted=0
            foreach($stream in $streams){
                $file=if($separate){'InstaFlow_'+$stream.role+'.'+$stream.ext}else{MediaName ([string]$item.title) ([string]$stream.ext) $counter}
                try {
                    SubmitIDM $idm ([string]$stream.url) $folder $file
                    $sent++
                    $submitted++
                } catch { [void]$errors.Add('IDM did not accept link '+$counter+' ('+$stream.role+'): '+$_.Exception.Message) }
            }
            if($separate -and $submitted -eq 2){
                PrepareMergeShortcut $folder
                $mergeTasks++
            }
        }
        if($sent -gt 0){
            State 'Direct media links were sent to IDM.' 100
            $message=$sent+' direct media links were sent to IDM. Check the download status in IDM.'
            if($mergeTasks -gt 0){$message+=' For '+$mergeTasks+' videos, video and audio were sent separately. After both downloads finish, run Merge_IDM.cmd inside each video folder to create a merged MKV.'}
            if([string]$job.quality -eq 'audio_mp3'){$message+=' Note: IDM downloads the original audio format and does not convert it directly to MP3.'}
            if($errors.Count -gt 0){$message+=' Issues: '+($errors -join ' | ')}
            Result @{ok=$true;count=$sent;mergeTasks=$mergeTasks;message=$message;items=@()}
            exit 0
        }
        Fail ('No direct media links were sent. '+($errors -join ' | '))
    }
    if ([string]$job.mode -eq 'download') {
        $items=@($job.items)
        if ($items.Count -eq 0) { Fail 'No items are selected.' }
        $target=[string]$job.output
        if (-not (Test-Path -LiteralPath $target)) { New-Item -ItemType Directory -Force -Path $target | Out-Null }
        $quality=[string]$job.quality
        $audioOnly=($quality -like 'audio_*')
        $audioType=if($quality -eq 'audio_m4a'){'m4a'}else{'mp3'}
        $container=[string]$job.container
        if($container -notin @('mkv','mp4')){$container='mkv'}
        $imageFormat=[string]$job.imageFormat
        if ($imageFormat -notin @('original','jpg','png')) { $imageFormat='original' }
        $before=@{}
        if ($imageFormat -ne 'original') { Get-ChildItem -LiteralPath $target -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object { $before[$_.FullName]=$true } }
        $okCount=0
        $failures=New-Object System.Collections.ArrayList
        # For Instagram galleries, download selected indices with a single gallery-dl invocation.
        $galleryEntries=@($items | Where-Object { $_.engine -eq 'gallery' -and (-not $audioOnly -or $_.kind -eq 'Video') })
        $skippedImages=@($items | Where-Object {$audioOnly -and $_.kind -eq 'Image'}).Count
        if($skippedImages -gt 0){[void]$failures.Add('In audio-only mode, '+$skippedImages+' images were skipped.')}

        if ($galleryEntries.Count -gt 0) {
            if (-not $gallery) { Fail 'gallery-dl was not found. Run the installation again.' }
            $ids = @($galleryEntries | ForEach-Object { [int]$_.selectIndex } | Sort-Object -Unique)
            $range = $ids -join ','
            State ('Downloading '+$galleryEntries.Count+' Instagram items...') 12
            $galleryUrl=[string]$galleryEntries[0].downloadUrl
            $galleryTarget=$target
            if($audioOnly){$galleryTarget=Join-Path $work 'GalleryAudio';New-Item -ItemType Directory -Force -Path $galleryTarget|Out-Null}
            $galleryArgs=@('--cookies-from-browser',([string]$job.browser),'--no-input','--retries','2','--range',$range,'--windows-filenames','-D',$galleryTarget)
            if($galleryUrl -match '/avatar/?(?:[?]|$)'){$galleryArgs+=@('-o','extractor.instagram.user-strategy=web,search')}
            $galleryArgs+=@('--',$galleryUrl)
            & $gallery @galleryArgs 2>&1 | Out-File -FilePath $log -Encoding UTF8 -Append
            $galleryCode=$LASTEXITCODE
            if($galleryCode -eq 0 -and -not $audioOnly){$okCount += $galleryEntries.Count}
            elseif($galleryCode -eq 0 -and $audioOnly){
                $ff=Tool 'ffmpeg.exe'
                if(-not $ff){[void]$failures.Add('FFmpeg is required to extract audio from gallery videos.')}
                else {
                    $videos=@(Get-ChildItem -LiteralPath $galleryTarget -File -Recurse -ErrorAction SilentlyContinue | Where-Object {$_.Extension.ToLower() -in @('.mp4','.mov','.webm','.mkv','.m4v')})
                    if($videos.Count -eq 0){[void]$failures.Add('No video files were found for audio extraction.')}
                    $audioNum=0
                    foreach($video in $videos){
                        $audioNum++
                        $outAudio=Join-Path $target (MediaName $video.BaseName $audioType $audioNum)
                        $ffArgs=@('-nostdin','-hide_banner','-loglevel','error','-y','-i',$video.FullName,'-vn')
                        if($audioType -eq 'mp3'){$ffArgs+=@('-codec:a','libmp3lame','-qscale:a','2')}
                        else{$ffArgs+=@('-codec:a','aac','-b:a','256k')}
                        $ffArgs+=@($outAudio)
                        & $ff @ffArgs 2>&1 | Out-File -LiteralPath $log -Encoding UTF8 -Append
                        if($LASTEXITCODE -eq 0 -and (Test-Path -LiteralPath $outAudio)){$okCount++}
                        else{[void]$failures.Add('Audio from video '+$audioNum+' could not be extracted. The video may not contain audio.')}
                    }
                }
            }
            else { [void]$failures.Add('Some Instagram media could not be downloaded (code '+$galleryCode+').') }
        }
        $ytEntries=@($items | Where-Object { $_.engine -eq 'yt' })
        $num=0
        foreach ($item in $ytEntries) {
            $num++
            if (-not $yt) { Fail 'yt-dlp is not installed.' }
            $pct=[int](20+(65*($num-1)/[Math]::Max(1,$ytEntries.Count)))
            State ('Downloading video '+$num+' of '+$ytEntries.Count+'...') $pct
            $videoUrl=[string]$item.url
            $args=@('--force-ipv4','--no-playlist','--newline','--no-warnings','--socket-timeout','15','--retries','2','--extractor-retries','1','--windows-filenames','-P',$target,'-o','%(title).160B [%(id)s].%(ext)s')
            if ($audioOnly) {
                $args+=@('-f','ba/b','-x','--audio-format',$audioType,'--audio-quality','0')
            } else {
                $format=if($quality -match '^(2160|1440|1080|720)$') {
                    'bv*[height<='+$quality+']+ba/b[height<='+$quality+']'
                } else {'bv*+ba/b'}
                $args+=@('-f',$format,'--merge-output-format',$container)
            }
            $args+=@('--',$videoUrl)
            $success=$false

            # Public downloads are attempted without browser cookies first.
            if([bool]$job.accel) {
                $aria=Tool 'aria2c.exe'
                if ($aria) {
                    State ('Trying the multi-connection downloader: '+$num+'/'+$ytEntries.Count) $pct
                    $acceleratedArgs=@('--downloader',$aria,'--downloader-args','aria2c:-x 4 -s 4 -k 2M') + $args
                    & $yt @acceleratedArgs 2>&1 | Out-File -FilePath $log -Encoding UTF8 -Append
                    $success=($LASTEXITCODE -eq 0)
                    if(-not $success) {
                        'aria2c failed; retrying with native yt-dlp downloader without browser cookies.' | Out-File -LiteralPath $log -Encoding UTF8 -Append
                        State 'The accelerated downloader failed. Retrying with the native downloader...' $pct
                    }
                } else {
                    'aria2c missing; using yt-dlp native downloader without browser cookies.' | Out-File -LiteralPath $log -Encoding UTF8 -Append
                    State 'aria2c is not installed. Using the native downloader...' $pct
                }
            }

            if (-not $success) {
                & $yt @args 2>&1 | Out-File -FilePath $log -Encoding UTF8 -Append
                $success=($LASTEXITCODE -eq 0)
            }

            # Only restricted content gets a final browser-cookie retry.
            if(-not $success -and [string]$job.browser -in @('firefox','chrome','edge')) {
                ('Public download failed; retrying with '+[string]$job.browser+' browser cookies.') | Out-File -LiteralPath $log -Encoding UTF8 -Append
                State ('Public download failed. Retrying with '+[string]$job.browser+' cookies...') $pct
                $cookieArgs=@('--cookies-from-browser',([string]$job.browser)) + $args
                & $yt @cookieArgs 2>&1 | Out-File -FilePath $log -Encoding UTF8 -Append
                $success=($LASTEXITCODE -eq 0)
            }
            if ($success) { $okCount++ }
            else { [void]$failures.Add('Error on item '+$num+': '+$item.title) }
        }
        if ($okCount -gt 0 -and $imageFormat -ne 'original') {
            # Keep the originals and create new converted copies only for this download.
            $ff=Tool 'ffmpeg.exe'
            if ($ff) {
                $imgs=@(Get-ChildItem -LiteralPath $target -Recurse -File -ErrorAction SilentlyContinue |
                    Where-Object { -not $before.ContainsKey($_.FullName) -and $_.Extension.ToLower() -in @('.png','.jpg','.jpeg','.webp','.bmp') })
                foreach($f in $imgs) {
                    if ($f.Extension.TrimStart('.').ToLower() -eq $imageFormat) { continue }
                    $destImage=[System.IO.Path]::ChangeExtension($f.FullName,$imageFormat)
                    if (Test-Path -LiteralPath $destImage) { continue }
                    $a=@('-nostdin','-hide_banner','-loglevel','error','-y','-i',$f.FullName,'-frames:v','1')
                    if ($imageFormat -eq 'jpg') {$a+=@('-q:v','2')}
                    $a+=@($destImage)
                    & $ff @a 2>&1 | Out-File -FilePath $log -Encoding UTF8 -Append
                    if ($LASTEXITCODE -ne 0) {
                        [void]$failures.Add('Conversion of '+$f.Name+' failed.')
                        if(Test-Path -LiteralPath $destImage){Remove-Item -LiteralPath $destImage -Force -ErrorAction SilentlyContinue}
                    }
                }
            } else { [void]$failures.Add('FFmpeg is not installed for image conversion.') }
        }
        if ($okCount -gt 0) {
            State 'Download complete' 100
            $msg='Downloaded '+$okCount+' items successfully.'
            if ($failures.Count -gt 0) { $msg+=' Some items failed: '+($failures -join ' | ') }
            Result @{ok=($failures.Count -eq 0); partial=$true; count=$okCount; items=@(); message=$msg }
            exit 0
        }
        Fail (ReadLastError ('Download failed. '+($failures -join ' | ')))
    }
    Fail 'Invalid operation type.'
} catch {
    Fail ('Application error: '+$_.Exception.Message)
}