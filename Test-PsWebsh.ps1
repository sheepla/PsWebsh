#!/usr/bin/env pwsh

Remove-Module PsWebsh
Import-Module PsWebsh

Invoke-Websh "screenfetch"

Invoke-Websh "unko.shout PowerShell | textimg -s" -ShowImage

$imageCacheDir = Join-Path $env:Temp "websh"
Get-ChildItem $imageCacheDir
sleep 2
Clear-WebshImageCache
if ($null -eq (Get-ChildItem $imageCacheDir)) { "Image cache deleted." } else { "Image cache has not deleted."  }

Test-WebshStatus
