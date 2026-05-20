# MikroTik DHCP Config Generator

Generates a RouterOS `.rsc` config for a DHCP-only MikroTik (RB941-2nD or similar).

## Files needed

| File | Purpose |
|------|---------|
| `generate-config.ps1` | The generator script |
| `template.rsc` | The config template (must be in the same folder) |

## Setup

Copy the whole **Microtik** folder to `C:\` on your laptop so the path is:

```
C:\Microtik
```

## How to run

Open PowerShell and run:

```powershell
cd C:\Microtik
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\generate-config.ps1
```

You'll be prompted for each value. Press Enter to accept defaults where shown.

Or pass everything on one line (no prompts):

```powershell
.\generate-config.ps1 -SchoolName "MySchool" -RouterIP "10.0.0.2" -SubnetCIDR "24" -Gateway "10.0.0.1" -PoolStart "10.0.0.10" -PoolEnd "10.0.0.200" -DNSServers "8.8.8.8,8.8.4.4"
```

## Deploy to a new router

1. Upload the generated `.rsc` file via **WinBox → Files**
2. In **Terminal**, run:

```
/import MySchool-mikrotik.rsc
```

The router will apply the full config — bridge, DHCP pool, firewall, NAT, DNS — and be ready to go.
