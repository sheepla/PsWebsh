#!/usr/bin/env pwsh

function Invoke-WebshApi
{
    Param
    (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$false, Position=0)]
        [String] $Code,

        [Parameter(Mandatory=$false, ValueFromPipeline=$false, ValueFromPipelineByPropertyName=$false, Position=1)]
        [String[]] $UploadImage
    )

    Set-Variable -Option Constant -Name URI -Value "https://websh.jiro4989.com/api/shellgei"

    # Check parameters
    if ($UploadImage.Length -gt 4) {
        Write-Error "Too many image path arguments. You can specify up to 4 image paths."
        return
    }
    
    # Make execution code
    $encodedCode = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($Code))
    $executionCode = "base64 -d <<< '{0}' | bash | base64" -f $encodedCode

    # Make base64 string from local image files
    $encodedImages = @()

    foreach ($path in $UploadImage) {
        # Convert image file to Base64 string
        $encodedImages += [Convert]::ToBase64String([IO.File]::ReadAllBytes((Resolve-Path $path)))
    }

    # Make body from hash table
    $body = @{
        code = $executionCode
        images = $encodedImages
    } | ConvertTo-Json

    # Send a request to the API
    $result = Invoke-RestMethod -Method POST -Uri $URI -Body $body

    # Print result
    Write-Output $result
}

function Invoke-Websh
{
    Param
    (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$false, Position=0)]
        [String] $Code,

        [Parameter(Mandatory=$false, ValueFromPipeline=$false, ValueFromPipelineByPropertyName=$false, Position=1)]
        [String[]] $UploadImage,

        [Parameter(Mandatory=$false, ValueFromPipeline=$false, ValueFromPipelineByPropertyName=$false)]
        [Switch] $ShowImage,

        [Parameter(Mandatory=$false, ValueFromPipeline=$false, ValueFromPipelineByPropertyName=$false)]
        [Switch] $NoSaveImage
    )

    # Check parameters
    if ($UploadImage.Length -gt 4) {
        Write-Error "Too many image path arguments. You can specify up to 4 image paths."
        return
    }
    if ($ShowImage -and $NoSaveImage) {
        Write-Error "ShowImage and NoSaveImage: Parameters cannot be specified at the same time"
        return
    }
    
    # Invoke API and get result
    if ($null -eq $UploadImage) {
        $result = Invoke-WebshApi -Code $Code
    } else {
        $result = Invoke-WebshApi -Code $Code -UploadImage $UploadImage
    }

    # Print stdout
    [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String(($result.stdout)))

    # Print stderr
    if ($result.stderr -ne "") {
        Write-Error "$($result.stderr)"
    }

    if (-not $NoSaveImage) {
        # Save image to file
        foreach ($resultImg in $result.images) {
            # Convert base64 encoded images to bytes
            $imageBytes = [Convert]::FromBase64String($resultImg.image)

            # Generate file path
            $now = [DateTime]::Now.ToString("yyyyMMdd_HHMMss_ffff")
            $ext = $resultImg.format
            $fileName = "{0}.{1}" -f "websh_${now}",$ext
            $destinationDir = Join-Path -Path ([IO.Path]::GetTempPath()) -ChildPath "websh"
            if (-not (Test-Path $destinationDir)) {
                New-Item -Type Directory $destinationDir
            }
            $destinationPath = Join-Path -Path $destinationDir -ChildPath $fileName

            # Write image bytes to a file
            [IO.File]::WriteAllBytes($destinationPath, $imageBytes)

            # Open image file via default viewer
            if ($ShowImage) {
                Invoke-Item $destinationPath
            }
        }
    }
}

function Test-WebshStatus
{
    Invoke-RestMethod -Uri "https://websh.jiro4989.com/api/ping"
}

function Clear-WebshImageCache
{
    $imageCacheDir = Join-Path -Path ([IO.Path]::GetTempPath()) -ChildPath "websh"
    Get-ChildItem $imageCacheDir | Remove-Item
}

Set-Alias -Name websh -Value Invoke-Websh

