InstaFlow Pro 2.5 - 4K and Accelerated Downloads

New: Accelerated 4K button uses yt-dlp + aria2c + FFmpeg, not expiring CDN links.
- yt-dlp determines actual max resolution (including 4K when available).
- aria2c attempts multi-connection download; speed improvement is not guaranteed.
- If aria2c fails, yt-dlp retries with its native engine.
- FFmpeg merges the original best video and audio without re-encoding when possible.
- The original Download button remains unchanged.
- Instagram gallery and profile functions remain as previously implemented; Instagram 429 can still block profile pictures.

Installation:
  1. Close InstaFlow.
  2. Extract ZIP to a regular folder.
  3. Run Install.bat.
  4. Re-open desktop shortcut InstaFlow Pro.

Why not IDM for 4K?
For some YouTube videos IDM extension sees only 1080p. Handing a signed CDN URL to IDM may fail 403 even when yt-dlp can download. This edition replaces the unreliable send-to-IDM button with an actual accelerated downloader. It is NOT an IDM integration.

If aria2c fails but native works, the video still downloads successfully.
YouTube content access may be restricted by YouTube's policies or rights.
