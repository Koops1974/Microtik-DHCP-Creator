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

1. **Plug the router** into the school's switch (any port works — all ports are bridged)
2. **Open WinBox** — the router appears in the neighbour list by its **MAC address**
3. **Double-click** to connect (no IP needed)
4. **Set admin username & password**
5. **Upload** the generated `.rsc` file via **Files → Upload**
6. Open **Terminal** and run:

```
/import MySchool-mikrotik.rsc
```

The router applies the config — bridge, DHCP pool, DNS — and starts handing out IPs immediately.

**Important:** The DNS server and gateway you enter must match the school network provided by the ISP. All ports are bridged so any port works for uplink or switches.
