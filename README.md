# k8s-dbg

Minimal Kubernetes debug image plus a sourceable `kdbg` shell launcher for starting an ad-hoc in-cluster troubleshooting pod.

## Image

`kdbg` defaults to `ghcr.io/vlanx/k8s-debug:latest`.

That image is published to GitHub Container Registry and rebuilt weekly via GitHub Actions so the toolset stays current. You can still override it with `KDBG_IMAGE` if needed, but no extra setup is required for the default path.

The image definition lives in [Dockerfile](/Users/tiago/Github/k8s-dbg/Dockerfile).

## Install the launcher script

Source [kdbg.sh](/Users/tiago/Github/k8s-dbg/kdbg.sh) from `~/.bashrc`, `~/.zshrc`, or your current shell session:

```sh
source /Users/tiago/Github/k8s-dbg/kdbg.sh
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
kubectl run k8s-debug-pod \
  --namespace default \
  --image ghcr.io/vlanx/k8s-debug:latest \
  --restart=Never \
  --rm \
  --attach \
  -it \
  --command -- /bin/sh

# Launch in kube-system namespace on a specific node
kubectl run k8s-debug-pod \
  --namespace kube-system \
  --image ghcr.io/vlanx/k8s-debug:latest \
  --restart=Never \
  --rm \
  --attach \
  -it \
  --overrides '{"apiVersion":"v1","spec":{"nodeName":"eu-west.compute.internal"}}' \
  --command -- /bin/sh

# Use a specific service account and run a one-shot DNS test
kubectl run k8s-debug-pod \
  --namespace default \
  --image ghcr.io/vlanx/k8s-debug:latest \
  --restart=Never \
  --rm \
  --attach \
  --overrides '{"apiVersion":"v1","spec":{"serviceAccountName":"net-debug"}}' \
  --command -- /bin/sh -lc 'dig kubernetes.default.svc.cluster.local'

# Capture packets from the host network namespace
kubectl run k8s-debug-pod \
  --namespace default \
  --image ghcr.io/vlanx/k8s-debug:latest \
  --restart=Never \
  --rm \
  --attach \
  --privileged \
  --overrides '{"apiVersion":"v1","spec":{"hostNetwork":true,"dnsPolicy":"ClusterFirstWithHostNet"}}' \
  --command -- /bin/sh -lc 'tcpdump -ni any port 53'
```
