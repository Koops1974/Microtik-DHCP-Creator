param(
    [string]$SchoolName,
    [string]$RouterIP,
    [string]$SubnetCIDR,
    [string]$Gateway,
    [string]$PoolStart,
    [string]$PoolEnd,
    [string]$DNSServers,
    [string]$OutputDir
)

# --- Helper functions ---
function Read-HostIfMissing {
    param($Value, $Prompt)
    if ($Value) { return $Value }
    return Read-Host $Prompt
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  MikroTik DHCP Config Generator" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# --- Prompts ---
$SchoolName  = Read-HostIfMissing -Value $SchoolName  -Prompt "School name (e.g. North-Park)"
$RouterIP    = Read-HostIfMissing -Value $RouterIP    -Prompt "Router IP (e.g. 10.0.0.2)"
$SubnetCIDR  = Read-HostIfMissing -Value $SubnetCIDR  -Prompt "Subnet CIDR (e.g. 24 = 255.255.255.0)"
$Gateway     = Read-HostIfMissing -Value $Gateway     -Prompt "Gateway (e.g. 10.0.0.1)"
$PoolStart   = Read-HostIfMissing -Value $PoolStart   -Prompt "DHCP pool start (e.g. 10.0.0.10)"
$PoolEnd     = Read-HostIfMissing -Value $PoolEnd     -Prompt "DHCP pool end (e.g. 10.0.0.200)"
$DNSServers  = Read-HostIfMissing -Value $DNSServers  -Prompt "DNS servers (e.g. 8.8.8.8,8.8.4.4)"

if (-not $DNSServers) { $DNSServers = "8.8.8.8,8.8.4.4" }

# --- Static leases ---
Write-Host ""
Write-Host "--- Static DHCP Leases (printers, servers, etc.) ---" -ForegroundColor Yellow
$staticLeases = @()

do {
    $addMore = Read-Host "Add a static lease? (y/n) [n]"
    if ($addMore -ne 'y') { break }

    $desc = Read-Host "  Description (e.g. Photocopier)"
    $ip   = Read-Host "  IP address (e.g. 10.0.0.50)"
    $mac  = Read-Host "  MAC address (e.g. AA:BB:CC:DD:EE:FF)"

    if ($desc -and $ip -and $mac) {
        $staticLeases += @{ Description = $desc; IP = $ip; MAC = $mac }
        Write-Host "  Added: $desc ($ip - $mac)" -ForegroundColor Green
    } else {
        Write-Host "  Skipped - all fields required" -ForegroundColor Red
    }
} while ($true)

# --- Compute values ---
$PoolRanges = "${PoolStart}-${PoolEnd}"
$SSID = "MikroTik-DHCP-$($SchoolName -replace '\s','')"
$Date = Get-Date -Format "MMM/dd/yyyy HH:mm:ss"

$ipParts = $RouterIP -split '\.'
if ($ipParts.Length -eq 4) {
    $NetworkAddr = "$($ipParts[0]).$($ipParts[1]).$($ipParts[2]).0"
} else {
    $NetworkAddr = $RouterIP
}

# --- Generate static lease lines ---
$leaseLines = ""
if ($staticLeases.Count -gt 0) {
    $leaseLines = "/ip dhcp-server lease`n"
    foreach ($lease in $staticLeases) {
        $leaseLines += "add address=$($lease.IP) mac-address=$($lease.MAC) comment=""$($lease.Description)""`n"
    }
}

# --- Read and fill template ---
$templatePath = Join-Path -Path $PSScriptRoot -ChildPath "template.rsc"
if (-not (Test-Path $templatePath)) {
    Write-Host "Error: template.rsc not found at $templatePath" -ForegroundColor Red
    exit 1
}

$config = Get-Content -Path $templatePath -Raw

$replacements = @{
    "{{SCHOOL_NAME}}"      = $SchoolName
    "{{DATE}}"             = $Date
    "{{SSID}}"             = $SSID
    "{{DHCP_POOL_RANGES}}" = $PoolRanges
    "{{ROUTER_IP}}"        = $RouterIP
    "{{SUBNET_CIDR}}"      = $SubnetCIDR
    "{{NETWORK_ADDRESS}}"  = $NetworkAddr
    "{{GATEWAY}}"          = $Gateway
    "{{DNS_SERVERS}}"      = $DNSServers
    "{{STATIC_LEASES}}"    = $leaseLines
}

foreach ($key in $replacements.Keys) {
    $config = $config -replace [regex]::Escape($key), $replacements[$key]
}

# --- Write output ---
$safeName = $SchoolName -replace '[^\w\-]', '_'
if (-not $OutputDir) { $OutputDir = $PSScriptRoot }
$outputFile = Join-Path -Path $OutputDir -ChildPath "${safeName}-mikrotik.rsc"
$config | Set-Content -Path $outputFile -Encoding ASCII

# --- Summary ---
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  Config generated!" -ForegroundColor Green
Write-Host "  File: $outputFile" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Summary:" -ForegroundColor Yellow
Write-Host "  School:         $SchoolName"
Write-Host "  Router IP:      $RouterIP/$SubnetCIDR"
Write-Host "  Network:        $NetworkAddr/$SubnetCIDR"
Write-Host "  Gateway:        $Gateway"
Write-Host "  DHCP Pool:      $PoolStart - $PoolEnd"
Write-Host "  DNS:            $DNSServers"
Write-Host "  SSID:           $SSID"
if ($staticLeases.Count -gt 0) {
    Write-Host "  Static Leases:  $($staticLeases.Count) device(s)"
    foreach ($lease in $staticLeases) {
        Write-Host "    - $($lease.Description): $($lease.IP) ($($lease.MAC))"
    }
}
Write-Host ""
Write-Host "Port connections:" -ForegroundColor Yellow
Write-Host "  Any port can be used for any device (all ports are bridged)" -ForegroundColor White
Write-Host "  WARNING: Disable DHCP on your main router or this will conflict!" -ForegroundColor Red
Write-Host ""
Write-Host "How to use:" -ForegroundColor Cyan
Write-Host "  1. Upload $outputFile to the router via WinBox (Files)" -ForegroundColor White
Write-Host "  2. In Terminal, run: /import ${safeName}-mikrotik.rsc" -ForegroundColor White
Write-Host ""
