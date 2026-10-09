# Agents

Phase 1 of a self-hosted coding-agent platform. Each agent is one
[agent-sandbox](https://github.com/kubernetes-sigs/agent-sandbox) `Sandbox`
(`agents.x-k8s.io/v1beta1`) with its own Longhorn home volume. You reach them
by SSH, over Tailscale, to a gateway pod in the `agents` namespace. From there
the `agent` CLI creates and suspends Sandboxes and attaches with
[herdr](https://herdr.dev), which keeps the coding session alive after you
disconnect.

## One-time setup

1. Images are built by GitHub Actions (`.github/workflows/agent-images.yml`) on a
   native amd64 runner and pushed to `ghcr.io/levitrammell/agent-coding` and
   `ghcr.io/levitrammell/agent-gateway` (public packages, no pull secret). The
   workflow runs on pushes that touch `services/agents/images/**` or
   `services/agents/bin/agent`, weekly, or by hand:

   ```bash
   gh workflow run agent-images.yml --ref <branch>
   ```

   Tags: `latest`, `sha-<short>`, and `YYYYMMDD` on scheduled runs. Manifests use
   `:latest` with `imagePullPolicy: Always`, so new agents get the newest build;
   running ones keep theirs until restarted.

   The gateway build context is `services/agents`, not the Containerfile's own
   directory, because the image copies `bin/agent`. The coding image is Fedora
   with the same daily shell toolset as the owner's distrobox: zsh and
   oh-my-zsh, zoxide, zellij, neovim, uv, Go, Rust, Node, `gh`, `task`, herdr,
   and the claude, codex, and grok CLIs plus their ACP adapters.

2. Install the agent-sandbox controller, the `agents` namespace, the quota,
   and the gateway:

   ```bash
   kubectl apply -k services/agents
   ```

3. Optional, for non-interactive harness use. One Secret, shared by every
   Sandbox (`envFrom` with `optional: true`, so a missing Secret is fine):

   ```bash
   kubectl -n agents create secret generic agent-credentials \
     --from-literal=CLAUDE_CODE_OAUTH_TOKEN=... \
     --from-literal=OPENAI_API_KEY=... \
     --from-literal=XAI_API_KEY=...
   ```

   - `CLAUDE_CODE_OAUTH_TOKEN` — Claude Code. Create one with `claude setup-token`.
   - `OPENAI_API_KEY` — Codex.
   - `XAI_API_KEY` — Grok. Mint a key at <https://console.x.ai>. Grok uses it
     when no browser session token is present.

   Interactive `claude login`, `codex login`, and `grok login` also work. Each
   CLI stores its own credentials under `$HOME` on that agent's home volume,
   so they survive suspend and resume.

## Daily use

Once Tailscale MagicDNS resolves the gateway (`tailscale.com/hostname: agents`):

```bash
ssh levi@agents
```

Login is key-only, as user `levi`. On the gateway:

```bash
agent new foo                          # create agent-foo and attach via herdr
agent new foo --repo https://github.com/org/repo.git --no-attach
agent ls
agent attach foo                       # resume if suspended, then herdr
agent shell foo                        # resume if suspended, then zsh -l
agent stop foo                         # suspend: pod goes away, home volume stays
agent start foo
agent rm foo                           # asks you to type the name; deletes the home PVC
```

The same `agent` script works from a Mac whose kubeconfig already points at
the cluster. `AGENTS_NAMESPACE` (default `agents`) and `AGENT_IMAGE` (default
`ghcr.io/levitrammell/agent-coding:latest`) override the defaults. `agent new
--dry-run` prints the Sandbox manifest and does not talk to the cluster.

Inside a Sandbox the home directory is `/home/agent` (uid 1000), with passwordless
sudo. `herdr` with no subcommand is the session: run it again to reattach.
`claude`, `codex`, `grok`, herdr, zellij, neovim, uv, Go, Rust, Node, `gh`,
and `task` are on `PATH`. The login shell is zsh.

## Capacity

`ResourceQuota/agents-capacity` in the `agents` namespace:

| Resource | Cap | What hitting it looks like |
| --- | --- | --- |
| pods | 6 | The gateway uses one pod. Five Sandboxes can run; the sixth Sandbox pod is rejected. |
| requests.cpu | 6 | A Sandbox whose CPU request does not fit is rejected. The gateway asks for 50m. |
| requests.memory | 12Gi | Same, for memory requests. Default Sandbox request is 1Gi. |
| limits.memory | 32Gi | Sum of container memory limits. Default Sandbox limit is 6Gi. |
| persistentvolumeclaims | 8 | Gateway host keys use one PVC. Each Sandbox home volume uses another, including suspended ones. The eighth claim is rejected. |
| requests.storage | 200Gi | Sum of PVC requests. Gateway is 1Gi; default Sandbox disk is 20Gi. |

Container defaults when a manifest omits them (`LimitRange/agents-defaults`):
request 250m / 512Mi, limit 2 CPU / 4Gi. `agent new` always sets its own
requests and limits (defaults: 500m / 1Gi request, 4 CPU / 6Gi limit, 20Gi disk).

## Phase 1 limits

- No warm pool. Every `agent new` is a cold start.
- No per-agent credential proxy. `agent-credentials`, if you create it, is
  namespace-wide and visible to every Sandbox.
- `agent rm` deletes the Sandbox and its home PVC. There is no trash or undo.
