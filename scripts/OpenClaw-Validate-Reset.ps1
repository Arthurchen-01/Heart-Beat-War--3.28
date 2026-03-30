[CmdletBinding()]
param(
    [ValidateSet('Validate', 'Apply', 'Reset')]
    [string]$Action = 'Validate',

    [string]$InventoryPath = '',

    [switch]$SkipLocal,

    [switch]$SkipRemote
)

$ErrorActionPreference = 'Stop'

if (-not $InventoryPath) {
    $InventoryPath = Join-Path (Split-Path -Path $PSScriptRoot -Parent) 'config\OpenClaw-Hosts.local.ps1'
}

function Write-Step {
    param(
        [string]$Message,
        [ConsoleColor]$Color = [ConsoleColor]::Cyan
    )

    Write-Host "== $Message" -ForegroundColor $Color
}

function Ensure-Command {
    param([string]$Name)

    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        throw "Missing required command: $Name"
    }
}

function Ensure-Directory {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -ItemType Directory -Force -Path $Path | Out-Null
    }
}

function Ensure-NoteProperty {
    param(
        [object]$Object,
        [string]$Name,
        [object]$DefaultValue
    )

    if ($null -eq $Object.PSObject.Properties[$Name]) {
        $Object | Add-Member -MemberType NoteProperty -Name $Name -Value $DefaultValue
    } elseif ($null -eq $Object.$Name) {
        $Object.PSObject.Properties.Remove($Name)
        $Object | Add-Member -MemberType NoteProperty -Name $Name -Value $DefaultValue
    }
}

function Ensure-ArrayContains {
    param(
        [object[]]$Values,
        [string[]]$Items
    )

    $buffer = @($Values)
    foreach ($item in $Items) {
        if ($buffer -notcontains $item) {
            $buffer += $item
        }
    }
    return $buffer
}

function Load-Inventory {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Inventory not found: $Path. Copy config/OpenClaw-Hosts.example.ps1 to config/OpenClaw-Hosts.local.ps1 and fill in your secrets."
    }

    $inventory = . $Path
    if (-not $inventory.Runtime -or -not $inventory.Local) {
        throw "Inventory file is missing Runtime or Local blocks: $Path"
    }

    return $inventory
}

function Ensure-Bundle {
    param([hashtable]$Runtime)

    if ($Action -eq 'Validate') {
        return
    }

    if (-not $Runtime.BundleSourcePath -or -not $Runtime.BundlePath) {
        return
    }

    if (-not (Test-Path -LiteralPath $Runtime.BundleSourcePath)) {
        throw "Bundle source path not found: $($Runtime.BundleSourcePath)"
    }

    Write-Step "Refreshing git bundle from $($Runtime.BundleSourcePath)"
    if (Test-Path -LiteralPath $Runtime.BundlePath) {
        Remove-Item -LiteralPath $Runtime.BundlePath -Force
    }

    & git -C $Runtime.BundleSourcePath bundle create $Runtime.BundlePath --all
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to create bundle at $($Runtime.BundlePath)"
    }
}

function Ensure-WorkspaceClone {
    param(
        [hashtable]$Runtime,
        [hashtable]$Agent
    )

    $workspace = $Agent.Workspace
    $workspaceParent = Split-Path -Path $workspace -Parent
    Ensure-Directory -Path $workspaceParent

    $roleFile = Join-Path $workspace '.agent-role.local'
    $gitDir = Join-Path $workspace '.git'
    $needsFresh = $Action -eq 'Reset'

    if (Test-Path -LiteralPath $workspace) {
        if (-not (Test-Path -LiteralPath $gitDir)) {
            $needsFresh = $true
        } elseif ((Test-Path -LiteralPath $roleFile) -and (((Get-Content -LiteralPath $roleFile -Raw).Trim()) -ne $Agent.Role)) {
            $needsFresh = $true
        }
    }

    if ($needsFresh -and (Test-Path -LiteralPath $workspace)) {
        $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
        $backup = "$workspace.bak-$stamp"
        Write-Step "Backing up local workspace to $backup" Yellow
        Move-Item -LiteralPath $workspace -Destination $backup
    }

    if (-not (Test-Path -LiteralPath $gitDir)) {
        Write-Step "Cloning runtime repo into $workspace"
        if ($Runtime.BundlePath -and (Test-Path -LiteralPath $Runtime.BundlePath)) {
            & git clone $Runtime.BundlePath $workspace
        } else {
            & git clone --branch $Runtime.Branch $Runtime.RepoUrl $workspace
        }
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to clone runtime repo into $workspace"
        }
    }

    & git -C $workspace remote set-url origin $Runtime.RepoUrl | Out-Null
    & git -C $workspace fetch origin $Runtime.Branch | Out-Null
    & git -C $workspace checkout $Runtime.Branch | Out-Null
    & git -C $workspace pull --rebase origin $Runtime.Branch | Out-Null
    & git -C $workspace config user.name $Agent.GitUser | Out-Null
    & git -C $workspace config user.email $Agent.GitEmail | Out-Null

    Set-Content -LiteralPath $roleFile -Value $Agent.Role -Encoding utf8

    $excludePath = Join-Path $workspace '.git\info\exclude'
    Ensure-Directory -Path (Split-Path -Path $excludePath -Parent)
    if (-not (Test-Path -LiteralPath $excludePath)) {
        New-Item -ItemType File -Path $excludePath | Out-Null
    }
    $exclude = Get-Content -LiteralPath $excludePath -ErrorAction SilentlyContinue
    if ($exclude -notcontains '.agent-role.local') {
        Add-Content -LiteralPath $excludePath -Value '.agent-role.local'
    }
}

function Update-LocalConfig {
    param(
        [hashtable]$Runtime,
        [hashtable]$Agent
    )

    $configPath = $Agent.ConfigPath
    if (-not (Test-Path -LiteralPath $configPath)) {
        throw "OpenClaw config not found: $configPath"
    }

    $data = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json

    Ensure-NoteProperty -Object $data -Name 'agents' -DefaultValue ([pscustomobject]@{})
    Ensure-NoteProperty -Object $data.agents -Name 'defaults' -DefaultValue ([pscustomobject]@{})
    $data.agents.defaults.workspace = $Agent.Workspace

    Ensure-NoteProperty -Object $data.agents.defaults -Name 'heartbeat' -DefaultValue ([pscustomobject]@{})
    $data.agents.defaults.heartbeat.every = $Agent.HeartbeatEvery
    $data.agents.defaults.heartbeat.target = 'feishu'
    $data.agents.defaults.heartbeat.directPolicy = 'allow'
    $data.agents.defaults.heartbeat.prompt = $Runtime.HeartbeatPrompt
    $data.agents.defaults.heartbeat.ackMaxChars = 300
    $data.agents.defaults.heartbeat.lightContext = $true
    $data.agents.defaults.heartbeat.isolatedSession = $true

    Ensure-NoteProperty -Object $data -Name 'channels' -DefaultValue ([pscustomobject]@{})
    Ensure-NoteProperty -Object $data.channels -Name 'defaults' -DefaultValue ([pscustomobject]@{})
    $data.channels.defaults.heartbeat = [pscustomobject]@{
        showOk       = $true
        showAlerts   = $true
        useIndicator = $true
    }

    Ensure-NoteProperty -Object $data.channels -Name 'feishu' -DefaultValue ([pscustomobject]@{})
    $data.channels.feishu.appId = $Agent.AppId
    $data.channels.feishu.appSecret = $Agent.AppSecret
    $data.channels.feishu.requireMention = $true
    $data.channels.feishu.groupPolicy = 'open'
    $data.channels.feishu.domain = 'feishu'
    $data.channels.feishu.connectionMode = 'websocket'
    $data.channels.feishu.webhookPath = '/feishu/events'
    $data.channels.feishu.dmPolicy = 'pairing'
    $data.channels.feishu.reactionNotifications = 'own'
    $data.channels.feishu.typingIndicator = $true
    $data.channels.feishu.resolveSenderNames = $true

    Ensure-NoteProperty -Object $data -Name 'plugins' -DefaultValue ([pscustomobject]@{})
    $data.plugins.allow = Ensure-ArrayContains -Values $data.plugins.allow -Items @('openclaw-lark', 'feishu')
    Ensure-NoteProperty -Object $data.plugins -Name 'entries' -DefaultValue ([pscustomobject]@{})
    Ensure-NoteProperty -Object $data.plugins.entries -Name 'feishu' -DefaultValue ([pscustomobject]@{})
    $data.plugins.entries.feishu.enabled = $true
    if ($null -eq $data.plugins.entries.feishu.PSObject.Properties['config']) {
        $data.plugins.entries.feishu | Add-Member -MemberType NoteProperty -Name 'config' -Value ([pscustomobject]@{})
    }

    ($data | ConvertTo-Json -Depth 100) + "`n" | Set-Content -LiteralPath $configPath -Encoding utf8
}

function Restart-LocalGateway {
    param([hashtable]$Agent)

    $logDir = Join-Path $env:USERPROFILE '.openclaw\logs'
    Ensure-Directory -Path $logDir
    $logPath = Join-Path $logDir "gateway-$($Agent.Name).log"

    $gatewayProcs = Get-CimInstance Win32_Process | Where-Object {
        $_.CommandLine -match 'openclaw\.mjs\s+gateway'
    }
    foreach ($proc in $gatewayProcs) {
        Stop-Process -Id $proc.ProcessId -Force -ErrorAction SilentlyContinue
    }

    Start-Sleep -Seconds 2
    Start-Process -FilePath 'powershell.exe' -ArgumentList '-NoProfile', '-WindowStyle', 'Hidden', '-Command', "openclaw gateway *> '$logPath'" -WindowStyle Hidden
    Start-Sleep -Seconds 8
}

function Get-LocalStatus {
    param([hashtable]$Agent)

    $workspace = $Agent.Workspace
    $logPath = Join-Path $env:USERPROFILE ".openclaw\logs\gateway-$($Agent.Name).log"
    $gatewayProcs = Get-CimInstance Win32_Process | Where-Object {
        $_.CommandLine -match 'openclaw\.mjs\s+gateway'
    }

    return [pscustomobject]@{
        name         = $Agent.Name
        hostname     = $env:COMPUTERNAME
        workspace    = $workspace
        role         = (Get-Content -LiteralPath (Join-Path $workspace '.agent-role.local') -Raw).Trim()
        head         = (& git -C $workspace rev-parse --short HEAD).Trim()
        remote       = (& git -C $workspace remote get-url origin).Trim()
        processCount = @($gatewayProcs).Count
        processIds   = @($gatewayProcs | Select-Object -ExpandProperty ProcessId)
        logTail      = if (Test-Path -LiteralPath $logPath) { Get-Content -LiteralPath $logPath -Tail 10 } else { @() }
        configPath   = $Agent.ConfigPath
    }
}

function Invoke-RemoteHelper {
    param(
        [hashtable]$Inventory,
        [string]$Mode
    )

    $tempInventory = Join-Path $env:TEMP "openclaw-hosts-$([guid]::NewGuid().ToString('N')).json"
    try {
        $Inventory | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $tempInventory -Encoding utf8
        $helperPath = Join-Path $PSScriptRoot 'openclaw_remote.py'
        $output = & python $helperPath --inventory $tempInventory --action $Mode
        if ($LASTEXITCODE -ne 0) {
            throw "Remote helper failed"
        }
        return $output | ConvertFrom-Json
    }
    finally {
        if (Test-Path -LiteralPath $tempInventory) {
            Remove-Item -LiteralPath $tempInventory -Force
        }
    }
}

function Show-Status {
    param(
        [string]$Title,
        [object]$Items
    )

    Write-Step $Title Green
    $Items | ConvertTo-Json -Depth 8
}

Write-Host "========== OpenClaw Validate / Reset ==========" -ForegroundColor Red

Ensure-Command -Name 'git'
Ensure-Command -Name 'python'
Ensure-Command -Name 'openclaw'

$inventory = Load-Inventory -Path $InventoryPath
Ensure-Bundle -Runtime $inventory.Runtime

$localStatus = $null
if (-not $SkipLocal) {
    if ($Action -in @('Apply', 'Reset')) {
        Write-Step 'Applying local runtime state'
        Ensure-WorkspaceClone -Runtime $inventory.Runtime -Agent $inventory.Local
        Update-LocalConfig -Runtime $inventory.Runtime -Agent $inventory.Local
        Restart-LocalGateway -Agent $inventory.Local
    }

    Write-Step 'Collecting local status'
    $localStatus = Get-LocalStatus -Agent $inventory.Local
    Show-Status -Title 'Local Status' -Items $localStatus
}

$remoteStatus = $null
if (-not $SkipRemote -and $inventory.Remote.Count -gt 0) {
    Write-Step "Running remote mode: $($Action.ToLower())"
    $remoteStatus = Invoke-RemoteHelper -Inventory $inventory -Mode $Action.ToLower()
    Show-Status -Title 'Remote Status' -Items $remoteStatus
}

Write-Step 'Completed' Green
