function Main {
    $module = Test-ModuleManifest .\RackspaceCloudOffice.psd1
    [string] $version = $module.Version

    $d = New-TemporaryDirectory
    try {
        $moduleDir = New-Item -ItemType Directory -Path (Join-Path $d $module.Name)
        Copy-Item *.psd1 $moduleDir
        Copy-Item *.psm1 $moduleDir
        New-ZipFile $d ".\RackspaceCloudOffice-$version.zip"
    }
    finally {
        Remove-Item -Recurse $d
    }
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