﻿#requires -version 3

<#
.SYNOPSIS
REST client for the Rackspace Cloud Office API [1]

[1]: http://api-wiki.apps.rackspace.com/api-wiki/index.php/Main_Page
#>

[CmdletBinding()]
param(
    [string]$Path,

    [ValidateSet('Default', 'Get', 'Head', 'Post', 'Put', 'Delete', 'Trace', 'Options', 'Merge', 'Patch')]
    [string]$Method = 'Get',

    [ValidateSet('application/json', 'application/x-www-form-urlencoded')]
    [string]$ContentType = 'application/x-www-form-urlencoded',

    [string]$UnpaginateProperty,
    [string]$UserKey,
    [string]$SecretKey,
    [string]$BaseUrl,
    [string]$ConfgFile = "$env:LOCALAPPDATA\RsCloudOfficeApi.config",
    [switch]$SaveConfig,

    [Parameter(ValueFromPipeline=$true)]
    [hashtable]$Body
)

begin {

function Do-Begin {
    $script:UserKey   = Select-FirstValue $UserKey   { Get-ConfigFileNode /config/userKey }
    $script:SecretKey = Select-FirstValue $SecretKey { Get-ConfigFileNode /config/secretKey }
    $script:BaseUrl   = Select-FirstValue $BaseUrl `
        { Get-ConfigFileNode /config/baseUrl } `
        'https://api.emailsrvr.com'

    if ($SaveConfig) {
        Out-Config $ConfgFile $UserKey $SecretKey $BaseUrl

        if (-not $Path) {
            exit
        }
    }
}

function Do-Process {
    if ($UnpaginateProperty) {
        Unpaginate-Request $UnpaginateProperty {
            param([string[]]$queryStringArgs)
            $pagePath = Join-PathWithQueryString $Path $queryStringArgs
            Invoke-RsCLoudOFficeRequest Get "${BaseUrl}${pagePath}" $ContentType $UserKey $SecretKey
        }
    }
    else {
        $Body | Invoke-RsCLoudOFficeRequest $Method "${BaseUrl}${Path}" $ContentType $UserKey $SecretKey
    }
}

Add-Type -AssemblyName System.Security

function Invoke-RsCLoudOFficeRequest {
    param(
        [parameter(Mandatory=$true)] [Microsoft.PowerShell.Commands.WebRequestMethod]$Method,
        [parameter(Mandatory=$true)] [string]$Uri,
        [parameter(Mandatory=$true)] [string]$ContentType,
        [parameter(Mandatory=$true)] [string]$UserKey,
        [parameter(Mandatory=$true)] [string]$SecretKey,
        [Parameter(ValueFromPipeline=$true)] $Body
    )

    $userAgent = 'https://github.com/mkropat/Invoke-RsCloudOfficeRequest'

    $encodedBody = switch ($ContentType) {
        'application/json'                  { ConvertTo-Json -Depth 32 $Body }
        'application/x-www-form-urlencoded' { ConvertTo-FormUrlEncoded $Body }
    }

    try {
        Invoke-WebRequest -Method $Method -Uri $Uri `
            -ContentType $ContentType `
            -Body $encodedBody `
            -UserAgent $userAgent `
            -Headers @{
                'Accept' = 'application/json';
                'X-Api-Signature' = (Compute-ApiSignature $userAgent $UserKey $SecretKey);
            } |
            Convert-Response
    }
    catch [System.Net.WebException] {
        if (-not $_.Exception.Response) {
            throw $_
        }

        $code = $_.Exception.Response.StatusCode -as [int]
        $message = $_.Exception.Response.Headers['x-error-message']

        Write-Error "$code $message"
    }
}

filter Convert-Response {
    Write-Verbose "$($_.StatusCode) response"
    try {
        ConvertFrom-Json $_.Content
    }
    catch {
        $_.Content
    }
}

function ConvertTo-FormUrlEncoded([hashtable] $data) {
    if ($data) {
        $pairs = $data | foreach GetEnumerator | foreach {
            $k = [System.Net.WebUtility]::UrlEncode($_.Name)
            $v = [System.Net.WebUtility]::UrlEncode($_.Value)
            "$k=$v"
        }
        $pairs -join '&'
    }
}

function Compute-ApiSignature($userAgent, $userKey, $secretKey) {
    $timestamp = Get-Date -Format yyyyMMddHHmmss
    $hash = Compute-Sha1 ($userKey + $userAgent + $timestamp + $secretKey)
    "${userKey}:${timestamp}:${hash}"
}

function Compute-Sha1($data) {
    $hasher = New-Object System.Security.Cryptography.SHA1Managed
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($data)
    [System.Convert]::ToBase64String($hasher.ComputeHash($bytes))
}

function Unpaginate-Request {
    param(
        [string]$UnpaginateProperty,
        [scriptblock]$Request,
        [int]$Size = 50,
        [int]$Offset = 0
    )

    do {
        $page = & $Request @("offset=$Offset","size=$Size")

        $page | select -ExpandProperty $UnpaginateProperty -ErrorAction SilentlyContinue

        $Offset = $page.offset + $Size
    }
    while ($Offset -lt $page.total)
}

function Join-PathWithQueryString {
    param(
        [string]$BasePath,
        [string[]]$QueryStringArgs
    )

    $joined = $QueryStringArgs -join '&'

    if ($BasePath -match '\?') {
        "${BasePath}&${joined}"
    }
    else {
        "${BasePath}?${joined}"
    }
}

function Get-ConfigFileNode($nodePath) {
    [xml]$cfg = Get-Content $ConfgFile -ErrorAction SilentlyContinue
    if ($cfg) {
        $cfg.SelectNodes($nodePath) | select -First 1 -ExpandProperty '#text'
    }
}

function Out-Config {
    param(
        [parameter(Mandatory=$true)] [string]$Path,
        [parameter(Mandatory=$true)] [string]$UserKey,
        [parameter(Mandatory=$true)] [string]$SecretKey,
        [parameter(Mandatory=$true)] [string]$BaseUrl
    )
    @"
<?xml version="1.0" encoding="utf-8"?>
<config>
  <userKey>$UserKey</userKey>
  <secretKey>$SecretKey</secretKey>
  <baseUrl>$BaseUrl</baseUrl>
</config>
"@ | Out-File $Path -Encoding ascii
}

function Select-FirstValue {
    $args |
        foreach { if ($_ -is [scriptblock]) { & $_ } else { $_ } } |
        where { $_ } |
        select -First 1
}

Do-Begin

}

process { Do-Process }
