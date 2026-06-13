# flock-staging

Staging deployment of Flock (the `churchmessage` monorepo). Images are built
and pushed by `scripts/staging-deploy.sh` in that repo — use it for end-to-end
deploys; `kubectl apply -k .` applies manifests only.

- App: https://flock.home.ima.dev (web; `/graphql` gateway, `/v1` API,
  `/l/` short links, `/ws` Asterisk softphone WebSocket)
- Test-provider inbox (captured SMS/email/Slack/calls): https://flock-dev.home.ima.dev
- All message/voice providers are the repo's local simulators; nothing leaves
  the cluster. AI features use the shared GPU Ollama in the `ai` namespace.

## Secrets (one-time, not in git)

Vault/external-secrets isn't deployed on this cluster, so the app secret is
created imperatively:

```sh
kubectl create secret generic flock-secrets -n flock-staging \
  --from-literal=NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=pk_test_… \
  --from-literal=CLERK_SECRET_KEY=sk_test_… \
  --from-literal=JWT_SECRET=$(openssl rand -hex 32)
```

Clerk keys come from the dedicated **staging** Clerk application (the
publishable key is also baked into the web bundle at image build via
`.env.staging` in the churchmessage repo — keep the two in sync).

## Registry pull secret (one-time)

`registry.home.ima.dev` requires auth for pulls. Manifests reference
`imagePullSecrets: regcred`; create it by copying the working secret from the
`ai` namespace:

```sh
kubectl -n ai get secret regcred -o yaml \
  | sed 's/namespace: ai/namespace: flock-staging/' | kubectl apply -f -
```

## Asterisk RTP

`asterisk-rtp` pins MetalLB IP `10.179.1.180` (UDP 10000-10010) and the
asterisk Deployment advertises it via `ASTERISK_EXTERNAL_IP` — change both
together or browser call audio dies (signaling will still look fine).
