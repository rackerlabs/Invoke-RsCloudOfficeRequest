function Main {
    $module = Test-ModuleManifest .\RackspaceCloudOffice.psd1
    [string] $version = $module.Version

    $d = New-TemporaryDirectory
    try {
        $moduleDir = New-Item -ItemType Directory -Path (Join-Path $d $module.Name)
        Copy-Item *.psd1 $moduleDir
        Copy-Item *.psm1 $moduleDir
        New-ZipFile $d ".\RackspaceCloudOffice-$version.zip"
        Write-Host "Zip file created: RackspaceCloudOffice-$version.zip"
        Write-Host
    }
    finally {
        Remove-Item -Recurse $d
    }

    Write-Host 'Run the following command to publish the package to the Gallery:'
    Write-Host
    Write-Host -ForegroundColor Yellow -BackgroundColor Black 'Publish-Module -Name RackspaceCloudOffice -NuGetApiKey YOUR_KEY'
}

function New-TemporaryDirectory {
    $parent = [System.IO.Path]::GetTempPath()
    $name = [System.IO.Path]::GetRandomFileName()
    New-Item -ItemType Directory -Path (Join-Path $parent $name) -Force
}

Add-Type -Assembly System.IO.Compression.FileSystem

function New-ZipFile {
    param(
        [string]$DirPath,
        [string]$ZipPath
    )

    With-WorkingDirectory {
        [System.IO.Compression.ZipFile]::CreateFromDirectory($DirPath, $ZipPath)
    }
}

function With-WorkingDirectory {
    param(
        [scriptblock]$Code
    )

    $previous = [Environment]::CurrentDirectory
    try {
        $current = Get-Location -PSProvider FileSystem | select -ExpandProperty Path
        [Environment]::CurrentDirectory = $current
        & $Code
    }
    finally {
        [Environment]::CurrentDirectory = $previous
    }
}

Main