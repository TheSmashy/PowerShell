Function Get-PubIP {
    try {
        (Invoke-WebRequest http://ifconfig.me/ip -ErrorAction Stop).Content
    } catch {
        Write-Error "Unable to retrieve public IP."
    }
}

Function Get-Zulu {
 Get-Date -AsUTC -Format u
}

Function Get-Pass {
    param (
        [int]$length = 20, 
        [string]$charset = "48..57+65..90+97..122"
    )
    -join(48..57+65..90+97..122 | ForEach-Object { [char]$_ } | Get-Random -Count $length)
}

function uptime {
	Get-WmiObject win32_operatingsystem | select csname, @{LABEL='LastBootUpTime';
	EXPRESSION={$_.ConverttoDateTime($_.lastbootuptime)}}
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
