#requires -version 3

Add-Type -AssemblyName System.Security

function Invoke-RsCloudOfficeRequest {
    <#
    .SYNOPSIS
    REST client for the Rackspace Cloud Office API [1]

    [1]: http://api-wiki.apps.rackspace.com/api-wiki/index.php/Main_Page
    #>

    param(
        [Parameter(Mandatory=$true)]
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

        [switch]$WrapBodyInArray,

        [Parameter(ValueFromPipeline=$true)]
        $Body
    )

    begin {
        $UserKey = Get-UserKey $ConfgFile $UserKey
        if (-not $UserKey) {
            throw '-UserKey is required'
        }

        $SecretKey = Get-SecretKey $ConfgFile $SecretKey
        if (-not $SecretKey) {
            throw '-SecretKey is required'
        }

        $BaseUrl = Get-BaseUrl $ConfgFile $BaseUrl
    }

    process {
        if ($UnpaginateProperty) {
            Unpaginate-Request $UnpaginateProperty {
                param([string[]]$queryStringArgs)
                $pagePath = Join-PathWithQueryString $Path $queryStringArgs
                Invoke-SingleRequest Get "${BaseUrl}${pagePath}" $ContentType $UserKey $SecretKey
            }
        }
        else {
            $Body | Invoke-SingleRequest $Method "${BaseUrl}${Path}" $ContentType $UserKey $SecretKey
        }
    }
}

function Set-RsCloudOfficeConfig {
    param(
        [string]$UserKey,
        [string]$SecretKey,
        [string]$BaseUrl,
        [string]$ConfgFile = "$env:LOCALAPPDATA\RsCloudOfficeApi.config"
    )

    $UserKey = Get-UserKey $ConfgFile $UserKey
    if (-not $UserKey) {
        throw '-UserKey is required'
    }

    $SecretKey = Get-SecretKey $ConfgFile $SecretKey
    if (-not $SecretKey) {
        throw '-SecretKey is required'
    }

    $BaseUrl = Get-BaseUrl $ConfgFile $BaseUrl

    Out-Config $ConfgFile @{
        userKey=$UserKey
        secretKey=$SecretKey
        baseUrl=$BaseUrl
    }
}

Export-ModuleMember -Function @('Invoke-RsCloudOfficeRequest', 'Set-RsCloudOfficeConfig')

function Get-UserKey($ConfigFile, $UserKey) {
    Select-FirstValue $UserKey { Get-ConfigFileNode $ConfigFile /config/userKey }
}

function Get-SecretKey($ConfigFile, $SecretKey) {
    Select-FirstValue $SecretKey { Get-ConfigFileNode $ConfigFile /config/secretKey }
}

function Get-BaseUrl($ConfigFile, $BaseUrl) {
    Select-FirstValue $BaseUrl `
        { Get-ConfigFileNode $ConfigFile /config/baseUrl } `
        'https://api.emailsrvr.com'
}

function Invoke-SingleRequest {
    param(
        [parameter(Mandatory=$true)] [Microsoft.PowerShell.Commands.WebRequestMethod]$Method,
        [parameter(Mandatory=$true)] [string]$Uri,
        [parameter(Mandatory=$true)] [string]$ContentType,
        [parameter(Mandatory=$true)] [string]$UserKey,
        [parameter(Mandatory=$true)] [string]$SecretKey,
        [Parameter(ValueFromPipeline=$true)] $Body
    )

    $userAgent = 'https://github.com/rackerlabs/Invoke-RsCloudOfficeRequest'

    if ($WrapBodyInArray -and $Body -ne $null) {
        $Body = @(, $Body)
    }

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

function Get-ConfigFileNode($ConfigFile, $NodePath) {
    [xml]$cfg = Get-Content $ConfgFile -ErrorAction SilentlyContinue
    if ($cfg) {
        $cfg.SelectNodes($NodePath) | select -First 1 -ExpandProperty '#text' -ErrorAction SilentlyContinue
    }
}

function Out-Config {
    param(
        [parameter(Mandatory=$true)] [string]$Path,
        [parameter(Mandatory=$true)] [hashtable]$Config
    )

    $nodes = $Config.Keys | foreach {
        $val = $Config[$_]
        $val = [Security.SecurityElement]::Escape($val)
        "<$_>$val</$_>"
    }
    $nodes = $nodes -join "`n"

    @"
<?xml version="1.0" encoding="utf-8"?>
<config>
$nodes
</config>
"@ | Out-File $Path -Encoding ascii
}

function Select-FirstValue {
    $args |
        foreach { if ($_ -is [scriptblock]) { & $_ } else { $_ } } |
        where { $_ } |
        select -First 1
}
