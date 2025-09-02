cd c:\users\thesmashy\dropbox\code

Function Get-PubIP {
    $urls = @(
        'https://ifconfig.me/ip',
        'https://ipv4.icanhazip.com',
        'https://api.ipify.org'
    )
    foreach ($u in $urls) {
        try {
            return (Invoke-WebRequest -Uri $u -TimeoutSec 5 -UseBasicParsing).Content.Trim()
        } catch { continue }
    }
    throw "Unable to retrieve public IP from any endpoint."
}

Function Get-Zulu {
 Get-Date -AsUTC -Format u
}

Function Get-Pass {
    param(
        [int]$length = 20,
        [string]$charset = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789'
    )
    $chars = $charset.ToCharArray()
    $buf   = New-Object byte[] ($length)
    [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($buf)
    -join ($buf | ForEach-Object { $chars[ $_ % $chars.Length ] })
}

function uptime {
    $os = Get-CimInstance -ClassName Win32_OperatingSystem
    $lastBoot = $os.LastBootUpTime
    $uptime = (Get-Date) - $lastBoot
    Write-Host "System has been up for $($uptime.Days) days, $($uptime.Hours) hours, $($uptime.Minutes) minutes."
}

function df {
    Get-Volume | Select-Object DriveLetter, FileSystemLabel, @{Name="Size(GB)";Expression={[math]::Round($_.Size/1GB,2)}}, @{Name="Free(GB)";Expression={[math]::Round($_.SizeRemaining/1GB,2)}}
}

function touch($file) {
    if (Test-Path $file) {
        # Update last write time if the file exists
        (Get-Item $file).LastWriteTime = Get-Date
    } else {
        # Create a new file if it doesn't exist
        "" | Out-File $file -Encoding ASCII
    }
}

function reload-profile {
    . $PROFILE
    Write-Host "Profile reloaded successfully!"
}

function find-file($name) {
    Get-ChildItem -Recurse -File -Filter "*${name}*" -ErrorAction SilentlyContinue | ForEach-Object {
        "$($_.DirectoryName)\$($_.Name)"
    }
}

function unzip ($file) {
    $dirname = (Get-Item $file).Basename
    if (-not (Test-Path $dirname)) {
        New-Item -Force -ItemType directory -Path $dirname
        Expand-Archive $file -OutputPath $dirname -ShowProgress
        Write-Host "Extracted $file to $dirname"
    } else {
        Write-Host "Directory $dirname already exists!"
    }
}

function sed($file, $find, $replace) {
    (Get-Content $file -Raw -Encoding UTF8).replace("$find", "$replace") | Set-Content $file -Encoding UTF8
}

function which($name) {
	Get-Command $name | Select-Object -ExpandProperty Definition
}

function export($name, $value) {
	set-item -force -path "env:$name" -value $value;
}

function pkill($name) {
	ps $name -ErrorAction SilentlyContinue | kill
}

function pgrep($name) {
	ps $name
}

function ll {
    Get-ChildItem -Force | Format-Table -Property Mode, LastWriteTime, @{Name="Size(GB)";Expression={[math]::Round($_.Length/1GB, 2)}}, Name -AutoSize
}

function Hash-Folder {
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        [string]$OutFile = "$env:USERPROFILE\Desktop\hashes.csv",
        [string]$Algo = "SHA256"
    )
    if (!(Test-Path $Path)) { Write-Error "Path $Path not found."; return }

    $root = (Resolve-Path $Path).Path
    Get-ChildItem -Path $root -Recurse -File | ForEach-Object {
        $h = Get-FileHash -Algorithm $Algo -Path $_.FullName
        [PSCustomObject]@{
            HashAlgorithm = $h.Algorithm
            Hash          = $h.Hash
            Path          = $_.FullName
            RelativePath  = $_.FullName.Substring($root.Length).TrimStart('\','/')
            Length        = $_.Length
            LastWriteTime = $_.LastWriteTimeUtc
        }
    } | Export-Csv -Path $OutFile -NoTypeInformation
    Write-Host "Hashes written to $OutFile ($Algo)"
}

function Compare-Hashes {
    param(
        [Parameter(Mandatory)] [string]$OldCsv,
        [Parameter(Mandatory)] [string]$NewCsv
    )
    $old = Import-Csv $OldCsv | Select-Object Hash,RelativePath,Path
    $new = Import-Csv $NewCsv | Select-Object Hash,RelativePath,Path

    # Prefer RelativePath when available; fall back to Path
    $old = $old | ForEach-Object { $_.RelativePath = $_.RelativePath ?? $_.Path; $_ }
    $new = $new | ForEach-Object { $_.RelativePath = $_.RelativePath ?? $_.Path; $_ }

    $diff = Compare-Object -ReferenceObject $old -DifferenceObject $new -Property RelativePath,Hash -PassThru
    if (-not $diff) { Write-Host "✅ No differences." }
    else { $diff | Format-Table SideIndicator, RelativePath, Hash }
}

function Copy-WithVerify {
    param(
        [Parameter(Mandatory)] [string]$Source,
        [Parameter(Mandatory)] [string]$Dest,
        [string]$Algo = "SHA256"
    )
    robocopy $Source $Dest /MIR /R:1 /W:1 | Out-Null

    $oldCsv = Join-Path $env:TEMP ("old_" + (Get-Random) + ".csv")
    $newCsv = Join-Path $env:TEMP ("new_" + (Get-Random) + ".csv")

    Hash-Folder -Path $Source -OutFile $oldCsv -Algo $Algo
    Hash-Folder -Path $Dest   -OutFile $newCsv -Algo $Algo
    Compare-Hashes -OldCsv $oldCsv -NewCsv $newCsv
}
