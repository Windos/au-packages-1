﻿$ErrorActionPreference = 'Stop'; # stop on all errors
$packageName = 'PDFXchangeEditor' 
$toolsDir   = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$version    = $env:ChocolateyPackageVersion
$filename   = 'EditorV8.x86.msi'
$filename64 = 'EditorV8.x64.msi'
$primaryDownloadUrl = "http://downloads.pdf-xchange.com/$filename"
$primaryDownloadUrl64 = "http://downloads.pdf-xchange.com/$filename64"
$url        = "http://www.docu-track.co.uk/builds/$version/$filename"
$url64      = "http://www.docu-track.co.uk/builds/$version/$filename64"
$checksum   = '914341DC138CF862F83E8682206A827902898D2443363A4D188DA730C4AD13AC'
$checksum64 = '7BB09829A64808D108F68D8531B502620E234DE83CA955A89F5DE19AF75BDCAD'
$lastModified32 = New-Object -TypeName DateTimeOffset 2020, 8, 12, 22, 51, 15, 0 # Last modified time corresponding to this package version
$lastModified64 = New-Object -TypeName DateTimeOffset 2020, 8, 12, 22, 44, 56, 0 # Last modified time corresponding to this package version

# Tracker Software have fixed download URLs, but if the binary changes we can fall back to their alternate (but slower) download site
# so the package doesn't break.
function CheckDownload($url, $primaryDownloadUrl, [DateTimeOffset] $packageVersionLastModified)
{
    $headers = Get-WebHeaders -url $primaryDownloadUrl
    $lastModifiedHeader = $headers.'Last-Modified'

    $lastModified = [DateTimeOffset]::Parse($lastModifiedHeader, [Globalization.CultureInfo]::InvariantCulture)

    Write-Verbose "Package LastModified: $packageVersionLastModified"
    Write-Verbose "HTTP Last Modified  : $lastModified"

    if ($lastModified -ne $packageVersionLastModified) {
        Write-Warning "The download available at $primaryDownloadUrl has changed from what this package was expecting. Falling back to FTP for version-specific URL"
        $url
    } else {
        Write-Verbose "Primary URL matches package expectation"
        $primaryDownloadUrl
    }
}

$url = CheckDownload $url $primaryDownloadUrl $lastModified32
$url64 = CheckDownload $url64 $primaryDownloadUrl64 $lastModified64

$packageArgs = @{
  packageName   = $packageName
  unzipLocation = $toolsDir
  fileType      = 'MSI'
  url           = $url
  url64bit      = $url64
  silentArgs = '/quiet /norestart'
  validExitCodes= @(0, 3010, 1641)

  softwareName  = 'PDF-XChange Editor'

  checksum = $checksum
  checksumType  = 'sha256' 
  checksum64 = $checksum64
  checksumType64= 'sha256' 
}

$arguments = @{}

$packageParameters = Get-PackageParameters

if ($packageParameters) {
    # http://help.tracker-software.com/EUM/default.aspx?pageid=PDFXEdit3:switches_for_msi_installers
    $customArguments = @{}

    if ($arguments.ContainsKey("NoDesktopShortcuts")) {
        Write-Host "You want NoDesktopShortcuts"
        $customArguments.Add("DESKTOP_SHORTCUTS", "0")
    }

    if ($arguments.ContainsKey("NoUpdater")) {
        Write-Host "You want NoUpdater"
        $customArguments.Add("NOUPDATER", "1")
    }

    if ($arguments.ContainsKey("NoViewInBrowsers")) {
        Write-Host "You want NoViewInBrowsers"
        $customArguments.Add("VIEW_IN_BROWSERS", "0")
    }

    if ($arguments.ContainsKey("NoSetAsDefault")) {
        Write-Host "You want NoSetAsDefault"
        $customArguments.Add("SET_AS_DEFAULT", "0")
    }

    if ($arguments.ContainsKey("NoProgramsMenuShortcuts")) {
        Write-Host "You want NoProgramsMenuShortcuts"
        $customArguments.Add("PROGRAMSMENU_SHORTCUTS", "0")
    }

    if ($arguments.ContainsKey("KeyFile")) {
        if ($arguments["KeyFile"] -eq "") {
          Throw 'KeyFile needs a colon-separated argument; try something like this: --params "/KeyFile:C:\Users\foo\Temp\PDFXChangeEditor.xcvault".'
        } else {
          Write-Host "You want a KeyFile named $($arguments["KeyFile"])"
          $customArguments.Add("KEYFILE", $arguments["KeyFile"])
        }
    }

} else {
    Write-Debug "No Package Parameters Passed in"
}

if ($customArguments.Count) { 
    $packageArgs.silentArgs += " " + (($customArguments.GetEnumerator() | ForEach-Object { "$($_.Name)=$($_.Value)" } ) -join " ")
}

Install-ChocolateyPackage @packageArgs
