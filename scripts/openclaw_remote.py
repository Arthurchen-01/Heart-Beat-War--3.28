import argparse
import json
import os
import posixpath
import shlex
import sys

import paramiko


def q(value):
    return shlex.quote("" if value is None else str(value))


def run(client, command, timeout=120):
    stdin, stdout, stderr = client.exec_command(command, timeout=timeout)
    out = stdout.read().decode("utf-8", "replace")
    err = stderr.read().decode("utf-8", "replace")
    code = stdout.channel.recv_exit_status()
    return code, out, err


def validate_remote(client):
    command = r"""python3 - <<'PY'
import json
import pathlib
import subprocess

home = pathlib.Path.home()
cfg_path = home / ".openclaw" / "openclaw.json"
cfg = json.loads(cfg_path.read_text(encoding="utf-8"))
workspace = cfg.get("agents", {}).get("defaults", {}).get("workspace", "")
role_file = pathlib.Path(workspace) / ".agent-role.local"

def cmd(args):
    try:
        return subprocess.check_output(args, stderr=subprocess.STDOUT).decode("utf-8", "replace").strip()
    except subprocess.CalledProcessError as exc:
        return exc.output.decode("utf-8", "replace").strip()

result = {
    "hostname": cmd(["hostname"]),
    "workspace": workspace,
    "target": cfg.get("agents", {}).get("defaults", {}).get("heartbeat", {}).get("target", ""),
    "appId": cfg.get("channels", {}).get("feishu", {}).get("appId", ""),
    "groupPolicy": cfg.get("channels", {}).get("feishu", {}).get("groupPolicy", ""),
    "requireMention": cfg.get("channels", {}).get("feishu", {}).get("requireMention", ""),
    "role": role_file.read_text(encoding="utf-8").strip() if role_file.exists() else "",
    "head": cmd(["git", "-C", workspace, "rev-parse", "--short", "HEAD"]) if workspace else "",
    "remote": cmd(["git", "-C", workspace, "remote", "get-url", "origin"]) if workspace else "",
    "processes": cmd(["bash", "-lc", "ps -eo pid,ppid,lstart,cmd | grep -i openclaw | grep -v grep || true"]).splitlines(),
    "logs": {},
}

for name in ("gateway-agent2.log", "gateway-agent3.log"):
    path = home / ".openclaw" / "logs" / name
    if path.exists():
        result["logs"][name] = cmd(["tail", "-n", "12", str(path)]).splitlines()

print(json.dumps(result, ensure_ascii=False))
PY"""
    code, out, err = run(client, command, timeout=60)
    if code != 0:
        raise RuntimeError(err or out or "remote validate failed")
    return json.loads(out)


def upload_bundle(client, bundle_path, remote_path):
    sftp = client.open_sftp()
    try:
        directory = posixpath.dirname(remote_path)
        if directory:
            run(client, f"mkdir -p {q(directory)}", timeout=30)
        sftp.put(bundle_path, remote_path)
    finally:
        sftp.close()


def apply_remote(client, remote, runtime, action):
    bundle_path = runtime.get("BundlePath", "")
    bundle_remote_path = runtime.get("BundleRemotePath", "/tmp/project-designs.bundle")
    if action in {"apply", "reset"} and bundle_path and os.path.exists(bundle_path):
        upload_bundle(client, bundle_path, bundle_remote_path)

    workspace = remote["Workspace"]
    heartbeat_every = remote.get("HeartbeatEvery", "5m")
    log_file = f"~/.openclaw/logs/gateway-{remote['Name']}.log"
    sudo_prefix = ""
    if remote.get("Sudo"):
        sudo_prefix = f"printf '%s\\n' {q(remote['Password'])} | sudo -S "

    start_command = "openclaw gateway"
    pnpm_home = remote.get("PnpmHome", "")
    if pnpm_home:
        start_command = f"export PNPM_HOME={q(pnpm_home)}; export PATH=\\\"$PNPM_HOME:$PATH\\\"; openclaw gateway"

    script = f"""
set -e
export WORKSPACE={q(workspace)}
export ROLE={q(remote['Role'])}
export REPO_URL={q(runtime['RepoUrl'])}
export BRANCH={q(runtime.get('Branch', 'main'))}
export GIT_USER={q(remote['GitUser'])}
export GIT_EMAIL={q(remote['GitEmail'])}
export APP_ID={q(remote['AppId'])}
export APP_SECRET={q(remote['AppSecret'])}
export HEARTBEAT_EVERY={q(heartbeat_every)}
export HEARTBEAT_PROMPT={q(runtime['HeartbeatPrompt'])}
export ACTION={q(action)}
export BUNDLE_PATH={q(bundle_remote_path)}
mkdir -p "$(dirname "$WORKSPACE")" ~/.openclaw/logs
NEEDS_FRESH=0
if [ "$ACTION" = "reset" ]; then
  NEEDS_FRESH=1
elif [ ! -d "$WORKSPACE/.git" ]; then
  NEEDS_FRESH=1
elif [ -f "$WORKSPACE/.agent-role.local" ] && [ "$(cat "$WORKSPACE/.agent-role.local")" != "$ROLE" ]; then
  NEEDS_FRESH=1
fi
if [ "$NEEDS_FRESH" = "1" ] && [ -e "$WORKSPACE" ]; then
  mv "$WORKSPACE" "$WORKSPACE.bak-$(date +%Y%m%d-%H%M%S)"
fi
if [ ! -d "$WORKSPACE/.git" ]; then
  if [ -f "$BUNDLE_PATH" ]; then
    git clone "$BUNDLE_PATH" "$WORKSPACE"
    git -C "$WORKSPACE" remote set-url origin "$REPO_URL"
  else
    git clone --branch "$BRANCH" "$REPO_URL" "$WORKSPACE"
  fi
fi
git -C "$WORKSPACE" remote set-url origin "$REPO_URL"
timeout 45 git -C "$WORKSPACE" fetch origin "$BRANCH" || true
git -C "$WORKSPACE" checkout "$BRANCH" || true
timeout 45 git -C "$WORKSPACE" pull --rebase origin "$BRANCH" || true
printf "%s\\n" "$ROLE" > "$WORKSPACE/.agent-role.local"
mkdir -p "$WORKSPACE/.git/info"
touch "$WORKSPACE/.git/info/exclude"
grep -qxF '.agent-role.local' "$WORKSPACE/.git/info/exclude" || echo '.agent-role.local' >> "$WORKSPACE/.git/info/exclude"
git -C "$WORKSPACE" config user.name "$GIT_USER"
git -C "$WORKSPACE" config user.email "$GIT_EMAIL"
python3 - <<'PY'
import json
import pathlib
import os

cfg_path = pathlib.Path.home() / ".openclaw" / "openclaw.json"
data = json.loads(cfg_path.read_text(encoding="utf-8"))

def ensure(obj, key, default):
    if key not in obj or obj[key] is None:
        obj[key] = default
    return obj[key]

agents = ensure(data, "agents", {{}})
defaults = ensure(agents, "defaults", {{}})
defaults["workspace"] = os.environ["WORKSPACE"]
heartbeat = ensure(defaults, "heartbeat", {{}})
heartbeat["every"] = os.environ["HEARTBEAT_EVERY"]
heartbeat["target"] = "feishu"
heartbeat["directPolicy"] = "allow"
heartbeat["prompt"] = os.environ["HEARTBEAT_PROMPT"]
heartbeat["ackMaxChars"] = 300
heartbeat["lightContext"] = True
heartbeat["isolatedSession"] = True

channels = ensure(data, "channels", {{}})
channels_defaults = ensure(channels, "defaults", {{}})
channels_defaults["heartbeat"] = {{"showOk": True, "showAlerts": True, "useIndicator": True}}
feishu = ensure(channels, "feishu", {{}})
feishu["appId"] = os.environ["APP_ID"]
feishu["appSecret"] = os.environ["APP_SECRET"]
feishu["requireMention"] = True
feishu["groupPolicy"] = "open"
feishu["domain"] = "feishu"
feishu["connectionMode"] = "websocket"
feishu["webhookPath"] = "/feishu/events"
feishu["dmPolicy"] = "pairing"
feishu["reactionNotifications"] = "own"
feishu["typingIndicator"] = True
feishu["resolveSenderNames"] = True

plugins = ensure(data, "plugins", {{}})
allow = ensure(plugins, "allow", [])
for item in ("openclaw-lark", "feishu"):
    if item not in allow:
        allow.append(item)
entries = ensure(plugins, "entries", {{}})
feishu_entry = ensure(entries, "feishu", {{}})
feishu_entry["enabled"] = True
feishu_entry.setdefault("config", {{}})

cfg_path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\\n", encoding="utf-8")
PY
{sudo_prefix}pkill -9 -f openclaw-gateway || true
{sudo_prefix}pkill -9 -x openclaw || true
sleep 2
nohup bash -lc {q(start_command)} > {log_file} 2>&1 < /dev/null &
sleep 6
"""
    code, out, err = run(client, f"bash -lc {q(script)}", timeout=180)
    warning = None
    if code != 0:
        warning = {
            "applyExitCode": code,
            "applyStdout": [line for line in out.splitlines() if line],
            "applyStderr": [line for line in err.splitlines() if line],
        }
    return warning


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--inventory", required=True)
    parser.add_argument("--action", choices=["validate", "apply", "reset"], required=True)
    args = parser.parse_args()

    with open(args.inventory, "r", encoding="utf-8-sig") as handle:
        inventory = json.load(handle)

    results = []
    for remote in inventory.get("Remote", []):
        client = paramiko.SSHClient()
        client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        client.connect(
            remote["Host"],
            username=remote["User"],
            password=remote["Password"],
            timeout=20,
        )
        try:
            warning = None
            if args.action in {"apply", "reset"}:
                warning = apply_remote(client, remote, inventory["Runtime"], args.action)
            status = validate_remote(client)
            status["name"] = remote["Name"]
            if warning:
                status["applyWarning"] = warning
            results.append(status)
        finally:
            client.close()

    json.dump(results, sys.stdout, ensure_ascii=False, indent=2)


if __name__ == "__main__":
    main()
