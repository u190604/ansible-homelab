<# 
Hyper-V Host + VM Provisioning Script (Windows 11)

What it does:
- Enables Hyper-V + required components
- Creates a Gen2 VM with VHDX, CPU, RAM, NIC, Secure Boot config, ISO attached

Notes:
- Default Switch is managed by Windows and provides NAT + DHCP. You can't rename it or set its subnet easily.
- External switch bridges to your physical NIC to put VM on your LAN.

#>

# GLOBAL PARAMS
$VMPath        = "C:\VM";
$VHDPath       = "$VMPath\Disks\"
$VHDSizeGB     = 40


function Assert-Admin {
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) { throw "Run this script as Administrator." }
}

function Assert-Windows11 {
    $os = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"
    $build = [int]$os.CurrentBuild
    if (-not $build -or $build -lt 22000) {
        throw "This script requires Windows 11. Detected build: $build"
    } 
}

function Enable-HyperV {
    Write-Host "Enabling Hyper-V (if needed)..." -ForegroundColor Cyan

    $features = @(
        "Microsoft-Hyper-V-All",
        "HypervisorPlatform",
        "VirtualMachinePlatform"
    )

    foreach ($f in $features) {
        $state = (Get-WindowsOptionalFeature -Online -FeatureName $f).State
        if ($state -ne "Enabled") {
            Enable-WindowsOptionalFeature -Online -FeatureName $f -All -NoRestart | Out-Null
            Write-Host "  Enabled feature: $f"
        } else {
            Write-Host "  Already enabled: $f"
        }
    }

    # Hyper-V management tools (usually included, but ensure)
    $cap = Get-WindowsCapability -Online | Where-Object Name -like "Rsat.HyperV.Tools*"
    if ($cap -and $cap.State -ne "Installed") {
        Add-WindowsCapability -Online -Name $cap.Name | Out-Null
        Write-Host "  Installed capability: $($cap.Name)"
    }

    Write-Host "Hyper-V enablement complete. If this is the first run, a reboot may be required." -ForegroundColor Yellow
}

function Ensure-VMFolders {
    New-Item -ItemType Directory -Force -Path @($VMPath, (Split-Path $VHDPath -Parent)) | Out-Null
}

function New-OrUpdate-VM {
    # Validate ISO
    if (-not (Test-Path $ISOPath)) { throw "ISO not found: $ISOPath" }

    Ensure-VMFolders

    # Select switch
    if ($NetworkMode -eq "DefaultSwitch") {
        $switch = Get-VMSwitch | Where-Object Name -eq "Default Switch"
        if (-not $switch) { throw "Default Switch not found. Is Hyper-V installed and rebooted?" }
        $switchName = $switch.Name
        Write-Host "Using switch: $switchName" -ForegroundColor Green
    }
    elseif ($NetworkMode -eq "External") {
        $switch = Ensure-ExternalSwitch -SwitchName $ExternalSwitchName -NicName $ExternalNicName
        $switchName = $switch.Name
        Write-Host "Using switch: $switchName" -ForegroundColor Green
    }
    else {
        throw "Invalid NetworkMode '$NetworkMode'. Use 'DefaultSwitch' or 'External'."
    }

    # Create VHD if missing
    if (-not (Test-Path $VHDPath)) {
        Write-Host "Creating VHDX: $VHDPath ($VHDSizeGB GB)..." -ForegroundColor Cyan
        New-VHD -Path $VHDPath -SizeBytes (${VHDSizeGB}GB) -Dynamic | Out-Null
    } else {
        Write-Host "VHDX exists: $VHDPath" -ForegroundColor Green
    }

    # Create or update VM
    $vm = Get-VM -Name $VMName -ErrorAction SilentlyContinue
    if (-not $vm) {
        Write-Host "Creating VM '$VMName' (Gen2)..." -ForegroundColor Cyan
        $vm = New-VM -Name $VMName -Generation 2 -Path $VMPath -MemoryStartupBytes (${MemoryStartupGB}GB) -VHDPath $VHDPath -SwitchName $switchName
    } else {
        Write-Host "VM already exists: $VMName" -ForegroundColor Green
        # Ensure NIC is connected to desired switch
        $ad = Get-VMNetworkAdapter -VMName $VMName -ErrorAction SilentlyContinue
        if ($ad -and $ad.SwitchName -ne $switchName) {
            Connect-VMNetworkAdapter -VMName $VMName -SwitchName $switchName
            Write-Host "  Connected NIC to switch: $switchName"
        }
    }

    # CPU + Memory settings
    Set-VMProcessor -VMName $VMName -Count $CPUCount

    Set-VMMemory -VMName $VMName `
        -DynamicMemoryEnabled $true `
        -MinimumBytes (${MemoryMinGB}GB) `
        -StartupBytes (${MemoryStartupGB}GB) `
        -MaximumBytes (${MemoryMaxGB}GB)

    # Secure Boot: for most modern Linux, 'MicrosoftUEFICertificateAuthority' works.
    # If your distro ISO fails to boot, set SecureBoot off: Set-VMFirmware -VMName $VMName -EnableSecureBoot Off
    Set-VMFirmware -VMName $VMName -EnableSecureBoot On -SecureBootTemplate "MicrosoftUEFICertificateAuthority"

    # Attach ISO to DVD drive (create if missing)
    $dvd = Get-VMDvdDrive -VMName $VMName -ErrorAction SilentlyContinue
    if (-not $dvd) {
        Add-VMDvdDrive -VMName $VMName -Path $ISOPath | Out-Null
    } else {
        Set-VMDvdDrive -VMName $VMName -Path $ISOPath | Out-Null
    }

    # Ensure boot order: DVD first for install, then disk
    $dvd = Get-VMDvdDrive -VMName $VMName
    $hdd = Get-VMHardDiskDrive -VMName $VMName
    Set-VMFirmware -VMName $VMName -BootOrder @($dvd, $hdd)

    # Static MAC (optional)
    if ($UseStaticMac) {
        $ad = Get-VMNetworkAdapter -VMName $VMName
        if ($ad.MacAddressSpoofing -ne "Off") {
            Set-VMNetworkAdapter -VMName $VMName -MacAddressSpoofing Off | Out-Null
        }
        Set-VMNetworkAdapter -VMName $VMName -StaticMacAddress $StaticMac | Out-Null
        Write-Host "Set static MAC: $StaticMac" -ForegroundColor Green
    }

    # Useful integration services
    Enable-VMIntegrationService -VMName $VMName -Name "Guest Service Interface" -ErrorAction SilentlyContinue | Out-Null

    Write-Host "VM configured: $VMName" -ForegroundColor Green
}

# -----------------------------
# RUN
# -----------------------------
try {
    Assert-Windows11
    Assert-Admin
    Enable-HyperV

    # If Hyper-V was just enabled, you may need to reboot before the next part works.
    # We'll still try to proceed; if it fails, reboot and re-run.
    New-OrUpdate-VM

    Write-Host "Starting VM..." -ForegroundColor Cyan
    Start-VM -Name $VMName | Out-Null

    Write-Host "Done. Open Hyper-V Manager -> '$VMName' -> Connect to complete OS install." -ForegroundColor Green
}
catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    throw
}
