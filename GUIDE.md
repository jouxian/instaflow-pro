InstaFlow Pro 2.6 - Quick Guide

1. Extract the ZIP package and run Install.bat.
2. Open InstaFlow Pro from the desktop shortcut.
3. Paste an Instagram or YouTube link and click Scan Link.
4. Select the desired quality or output format.
5. Click Download. InstaFlow will automatically use the available download tools.

Runtime tools such as yt-dlp, Deno, FFmpeg, ffprobe, aria2c, and gallery-dl are downloaded automatically when required.

yt-dlp handles YouTube format selection.
FFmpeg merges separate video and audio streams when necessary.
aria2c can accelerate downloads when supported, but it is not always faster.
If accelerated downloading fails, InstaFlow automatically falls back to the native yt-dlp download method.

Public YouTube videos are attempted without browser cookies first.
Browser cookies are used only as a fallback when access restrictions require them.

Instagram may temporarily return HTTP 429 when too many requests are made. Avoid repeatedly scanning the same profile or media when rate-limited.

No external download manager is required.
