#!/bin/bash
# Gateway startup. Runs as root so sshd can bind port 22, then drops sessions to levi.
set -euo pipefail

AUTHORIZED_KEYS_SRC="/etc/agent-gateway/authorized-keys/authorized_keys"
HOSTKEY_DIR="/etc/ssh/hostkeys"
ED25519_KEY="${HOSTKEY_DIR}/ssh_host_ed25519_key"
RSA_KEY="${HOSTKEY_DIR}/ssh_host_rsa_key"

if ! getent group levi >/dev/null; then
  groupadd --gid 1000 levi
fi
if ! id levi >/dev/null 2>&1; then
  useradd --uid 1000 --gid 1000 --create-home --shell /bin/bash levi
fi
# Key-only SSH: '*' means no password can ever match. Not passwd -l: with
# UsePAM no, sshd rejects locked accounts even for public-key logins.
usermod -p '*' levi

install -d -m 700 -o levi -g levi /home/levi/.ssh
install -m 600 -o levi -g levi "$AUTHORIZED_KEYS_SRC" /home/levi/.ssh/authorized_keys

# Host keys live on the agent-gateway-hostkeys PVC. Generate them only when
# missing so the SSH host identity survives pod restarts.
install -d -m 755 "$HOSTKEY_DIR"
if [[ ! -f "$ED25519_KEY" ]]; then
  ssh-keygen -t ed25519 -f "$ED25519_KEY" -N "" -q
fi
if [[ ! -f "$RSA_KEY" ]]; then
  ssh-keygen -t rsa -b 4096 -f "$RSA_KEY" -N "" -q
fi
# kubelet's fsGroup pass widens existing key files; lock them back down before sshd starts.
chmod 600 "$ED25519_KEY" "$RSA_KEY"
chmod 644 "${ED25519_KEY}.pub" "${RSA_KEY}.pub"

cat > /etc/ssh/sshd_config <<EOF
Port 22
HostKey ${ED25519_KEY}
HostKey ${RSA_KEY}
PermitRootLogin no
PasswordAuthentication no
KbdInteractiveAuthentication no
ChallengeResponseAuthentication no
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys
AllowUsers levi
UsePAM no
X11Forwarding no
PrintMotd no
PidFile /run/sshd.pid
Subsystem sftp /usr/lib/openssh/sftp-server
EOF

install -d -m 700 -o levi -g levi /home/levi/.kube
cat > /home/levi/.kube/config <<'EOF'
apiVersion: v1
kind: Config
clusters:
  - name: in-cluster
    cluster:
      server: https://kubernetes.default.svc
      certificate-authority: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
users:
  - name: levi
    user:
      tokenFile: /var/run/secrets/kubernetes.io/serviceaccount/token
contexts:
  - name: levi
    context:
      cluster: in-cluster
      user: levi
      namespace: agents
current-context: levi
EOF
chown levi:levi /home/levi/.kube/config
chmod 600 /home/levi/.kube/config
chmod 755 /home/levi

printf 'export AGENTS_NAMESPACE=agents\n' > /etc/profile.d/agents.sh
chmod 644 /etc/profile.d/agents.sh

install -d -m 755 /run/sshd
exec /usr/sbin/sshd -D -e -f /etc/ssh/sshd_config
