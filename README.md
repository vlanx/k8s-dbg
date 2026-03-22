# k8s-dbg

Minimal Kubernetes debug image plus a sourceable `kdbg` shell launcher for starting an ad-hoc in-cluster troubleshooting pod.

## Why this exists

This image exists to provide a small, predictable, and reusable debug container for Kubernetes clusters.

Instead of relying on whatever tools happen to be available in application containers, or pulling in a much larger general-purpose troubleshooting image, this image keeps a deliberately small set of networking and inspection tools that are useful during cluster debugging sessions.

It is intentionally limited in scope:
- small Alpine-based image
- focused on in-cluster debugging and network troubleshooting
- no extra shell or editor customizations beyond what Alpine already provides
- privilege is opt-in at launch time, not the default

## Included tools

The image currently includes:

- `curl` for HTTP(S) requests and service probing
- `bind-tools` for DNS troubleshooting (`dig`, `nslookup`)
- `iproute2` for inspecting interfaces, routes, and addresses
- `netcat-openbsd` for simple TCP/UDP connectivity checks (`nc`)
- `jq` for parsing JSON responses from APIs and service endpoints
- `tcpdump` for packet capture when the pod is launched with sufficient privileges
- `busybox-extras` plus the default Alpine / BusyBox userland

The default shell is `/bin/sh`, as provided by Alpine.

## Image

`kdbg` defaults to `ghcr.io/vlanx/k8s-dbg:latest`.

That image is published to GitHub Container Registry and rebuilt weekly via GitHub Actions so the toolset stays current. You can still override it with `KDBG_IMAGE` if needed, but no extra setup is required for the default path. Check the [automation setup below](#update-policy).

The image definition lives in [Dockerfile](./kdbg.sh).

## Install the launcher script

Source [kdbg.sh](/Users/tiago/Github/k8s-dbg/kdbg.sh) from `~/.bashrc`, `~/.zshrc`, or your current shell session:

```sh
source ~/k8s-dbg/kdbg.sh
```

Or paste it into your helper `/scripts` folder if you have one.

## Usage

```sh
kdbg [options]
```

Flag values are always passed as the next argument, for example `--namespace kube-system` and `--cmd 'dig kubernetes.default.svc.cluster.local'`.

Supported flags:

- `-n`, `--namespace`: create the pod in a specific namespace. Defaults to `default`.
- `-N`, `--node`: pin the pod to a specific node with `spec.nodeName`.
- `--serviceaccount`: set the pod ServiceAccount. Defaults to `default`, which is the namespace's default ServiceAccount.
- `--privileged`: run the pod in privileged mode.
- `--host-network`: join the node network namespace and switch DNS policy to `ClusterFirstWithHostNet`.
- `--cmd`: run a one-shot command instead of opening an interactive shell.

#### Examples:

```sh
# Open a shell in the debug container in the current context and namespace
kdbg

# Launch in kube-system namespace on a specific node
kdbg --namespace kube-system --node eu-west.compute.internal

# Use a specific service account and run a one-shot DNS test
kdbg --serviceaccount net-debug --cmd 'dig kubernetes.default.svc.cluster.local'

# Capture packets from the host network namespace
kdbg --host-network --privileged --cmd 'tcpdump -ni any port 53'
```

#### Equivalent `kubectl run` commands:

```sh
# Open a shell in the default namespace
kubectl run k8s-dbg-pod \
  --namespace default \
  --image ghcr.io/vlanx/k8s-dbg:latest \
  --restart=Never \
  --rm \
  --attach \
  -it \
  --command -- /bin/sh

# Launch in kube-system namespace on a specific node
kubectl run k8s-debug-pod \
  --namespace kube-system \
  --image ghcr.io/vlanx/k8s-dbg:latest \
  --restart=Never \
  --rm \
  --attach \
  -it \
  --overrides '{"apiVersion":"v1","spec":{"nodeName":"eu-west.compute.internal"}}' \
  --command -- /bin/sh

# Use a specific service account and run a one-shot DNS test
kubectl run k8s-debug-pod \
  --namespace default \
  --image ghcr.io/vlanx/k8s-dbg:latest \
  --restart=Never \
  --rm \
  --attach \
  --overrides '{"apiVersion":"v1","spec":{"serviceAccountName":"net-debug"}}' \
  --command -- /bin/sh -lc 'dig kubernetes.default.svc.cluster.local'

# Capture packets from the host network namespace
kubectl run k8s-debug-pod \
  --namespace default \
  --image ghcr.io/vlanx/k8s-dbg:latest \
  --restart=Never \
  --rm \
  --attach \
  --privileged \
  --overrides '{"apiVersion":"v1","spec":{"hostNetwork":true,"dnsPolicy":"ClusterFirstWithHostNet"}}' \
  --command -- /bin/sh -lc 'tcpdump -ni any port 53'
```

## Update policy

The image is rebuilt regularly through GitHub Actions.

Because the Dockerfile pins the Alpine minor version (for example `alpine:3.22`), rebuilds automatically pick up:
- updated Alpine base layers within that minor line
- updated installed packages available for that same Alpine release

Minor-version upgrades of Alpine itself, such as moving from `3.22` to `3.23`, are manual and require changing the Dockerfile.
