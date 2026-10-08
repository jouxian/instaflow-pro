Dim sh, fso, appFile, cmd
Set sh = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")
appFile = fso.BuildPath(fso.GetParentFolderName(WScript.ScriptFullName), "InstaFlow.ps1")
cmd = "powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -WindowStyle Hidden -File " & Chr(34) & appFile & Chr(34)
sh.Run cmd, 0, False
