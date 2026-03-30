@{
    Runtime = @{
        RepoUrl          = 'https://github.com/OWNER/project-designs.git'
        Branch           = 'main'
        BundleSourcePath = 'C:\path\to\project-designs'
        BundlePath       = 'C:\path\to\project-designs.bundle'
        BundleRemotePath = '/tmp/project-designs.bundle'
        HeartbeatPrompt  = 'Read AGENTS.md and HEARTBEAT.md from the workspace root. Also read docs/OPERATING-MODEL.md and docs/MEMORY-MODEL.md when present. Detect role from the workspace path or .agent-role.local. Follow the role strictly. In single Feishu group mode, Agent 1 is the only intake endpoint for new user work. If nothing needs action, reply HEARTBEAT_OK.'
    }

    Local = @{
        Name           = 'agent1'
        Role           = 'agent1'
        Workspace      = "$env:USERPROFILE\.openclaw\workspace-agent1"
        ConfigPath     = "$env:USERPROFILE\.openclaw\openclaw.json"
        AppId          = 'cli_xxx'
        AppSecret      = '<local-feishu-secret>'
        GitUser        = 'agent-1'
        GitEmail       = 'agent1@local'
        HeartbeatEvery = '5m'
    }

    Remote = @(
        @{
            Name           = 'agent2'
            Host           = '150.158.17.181'
            User           = 'ubuntu'
            Password       = '<server-password>'
            Role           = 'agent2'
            Workspace      = '/home/ubuntu/.openclaw/workspace-agent2'
            AppId          = 'cli_xxx'
            AppSecret      = '<agent2-feishu-secret>'
            GitUser        = 'agent-2'
            GitEmail       = 'agent2@local'
            HeartbeatEvery = '3m'
            Sudo           = $true
            PnpmHome       = ''
        }
        @{
            Name           = 'agent3'
            Host           = '42.192.56.101'
            User           = 'root'
            Password       = '<server-password>'
            Role           = 'agent3'
            Workspace      = '/root/.openclaw/workspace-agent3'
            AppId          = 'cli_xxx'
            AppSecret      = '<agent3-feishu-secret>'
            GitUser        = 'agent-3'
            GitEmail       = 'agent3@local'
            HeartbeatEvery = '5m'
            Sudo           = $false
            PnpmHome       = '/root/.local/share/pnpm'
        }
    )
}
