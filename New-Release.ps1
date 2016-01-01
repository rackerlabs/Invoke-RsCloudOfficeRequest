param(
    [Parameter(Mandatory=$true)]
    [string]$Version
)

function Main {
    $d = New-TemporaryDirectory
    try {
        $moduleDir = New-Item -ItemType Directory -Path (Join-Path $d 'RackspaceCloudOffice')
        Copy-Item .\RackspaceCloudOffice.psm1 $moduleDir
        New-ZipFile $d ".\RackspaceCloudOffice-$Version.zip"
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