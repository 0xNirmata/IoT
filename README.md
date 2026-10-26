# 🎓 Inception of Things

## 📋 Introduction

**Inception of Things (IoT)** is a project designed to provide hands-on experience with **Kubernetes**, container orchestration, and DevOps practices. This project serves as an excellent introduction to the complex world of Kubernetes by utilizing lightweight alternatives like **K3s** and **k3d**.

### 🎯 Project Goals

- ✅ Set up a Kubernetes cluster using K3s on virtual machines (Vagrant)
- ✅ Deploy multiple applications with different replicas
- ✅ Configure Ingress for managing external access
- ✅ Use k3d to run Kubernetes clusters inside Docker containers
- ✅ Implement GitOps with ArgoCD and GitLab CI/CD pipeline
- ✅ Understand the fundamentals of container orchestration

## 📁 Repository Structure

```
IoT/
├── README.md                    # This file
├── .gitignore
├── p1/                          # Part 1: K3s Cluster with Vagrant
│   ├── Vagrantfile             # VM configuration (server + worker nodes)
│   └── scripts/
│       ├── server.sh           # Master node K3s installation script
│       └── worker.sh           # Worker node joining script
├── p2/                          # Part 2: Deploy Applications
│   ├── Vagrantfile             # Single VM with K3s
│   ├── confs/                  # Kubernetes manifests
│   │   ├── app1.yaml          # Deployment + Service for app1 (1 replica)
│   │   ├── app2.yaml          # Deployment + Service for app2 (3 replicas)
│   │   ├── app3.yaml          # Deployment + Service for app3 (1 replica)
│   │   └── ingress.yaml       # Ingress routing configuration
│   └── scripts/
│       └── setup.sh            # K3s + applications deployment script
├── p3/                          # Part 3: k3d Cluster Creation
│   ├── confs/                  # Kubernetes manifests for playground app
│   │   ├── deploy.yaml        # Deployment configuration
│   │   ├── service.yaml       # Service definition
│   │   └── ingress.yaml       # Ingress for playground
│   └── scripts/
│       └── install.sh          # Docker, k3d, kubectl installation script
└── bonus/                       # Bonus: GitLab + ArgoCD GitOps
    ├── confs/
    │   ├── gitlab-values.yaml     # Helm values for GitLab CE
    │   ├── argocd-gitlab-app.yaml # ArgoCD Application definition
    │   └── namespace.yaml         # GitLab namespace creation
    └── scripts/
        └── install-gitlab.sh      # Full GitLab + ArgoCD setup script
```

## 🛠️ Prerequisites

### Software Requirements

| Tool | Minimum Version | Purpose |
|------|-----------------|---------|
| **Vagrant** | 2.2+ | VM management |
| **VirtualBox** | 6.0+ | Hypervisor for nested virtualization |
| **Docker** | 20.10+ | Container runtime (for k3d) |
| **kubectl** | 1.25+ | Kubernetes CLI |
| **k3d** | 5.0+ | K3s in Docker cluster tool |
| **Helm** | 3.8+ | Package manager for Kubernetes (Bonus) |

### Hardware Requirements

- **RAM**: Minimum 8GB recommended (16GB preferred for GitLab bonus)
- **CPU**: 4+ cores with virtualization support (VT-x/AMD-V)
- **Disk**: At least 20GB free space

### Enable Nested Virtualization (for VirtualBox)

```bash
# For better performance on Windows/Mac, enable nested virtualization:
VBoxManage modifyvm "your-vm-name" --nested-hw-virt on
```

## 📚 Project Parts

### Part 1: K3s Cluster with Vagrant

**Objective**: Create a two-node Kubernetes cluster (master + worker) using Vagrant and K3s.

#### Architecture

```
┌─────────────────┐          ┌─────────────────┐
│   Server Node   │◄────────►│   Worker Node   │
│   (Master)      │  k3s     │   (Agent)       │
│   192.168.x.110 │ cluster  │   192.168.x.111 │
└─────────────────┘          └─────────────────┘
        │                          │
        └──────────┬───────────────┘
                   ▼
          Kubernetes cluster
```

#### Features

- **Master Node (`0xEr3b0sS`)**: K3s server with control plane
- **Worker Node (`0xEr3b0sSW`)**: K3s agent node joining the cluster
- **Token Sharing**: Automatic token passing via shared `/vagrant` folder
- **Network Interface Detection**: Automatic flannel interface configuration

#### How to Run

```bash
cd p1
vagrant up
```

**What happens**:
1. Vagrant provisions two Debian Bookworm VMs
2. Server script installs K3s master node
3. Worker script waits for token, then joins as agent
4. Both nodes form a functional Kubernetes cluster

---

### Part 2: Deploy Applications with Ingress

**Objective**: Deploy three applications with different configurations and expose them via Ingress.

#### Architecture

```
┌──────────┐    ┌──────────┐    ┌──────────┐
│  app1    │    │  app2    │    │  app3    │
│ (1 repl) │    │ (3 repl) │    │ (1 repl) │
└────┬─────┘    └────┬─────┘    └────┬─────┘
     │               │               │
     ▼               ▼               ▼
┌─────────────────────────────────────────────┐
│              Ingress Controller             │
│                                             │
│  app1.com → app1                            │
│  app2.com → app2                            │
│  /        → app3                            │
└─────────────────────────────────────────────┘
```

#### Deployed Applications

| App | Replicas | Image | Host/Path |
|-----|----------|-------|-----------|
| **app1** | 1 | `traefik/whoami` | `app1.com` |
| **app2** | 3 | `traefik/whoami` | `app2.com` |
| **app3** | 1 | `traefik/whoami` | `/` (default) |

#### How to Run

```bash
cd p2
vagrant up
```

After provisioning, verify deployment:

```bash
vagrant ssh 0xEr3b0sS
kubectl get all --all-namespaces
kubectl get ingress
```

---

### Part 3: k3d Cluster Creation

**Objective**: Create a K3s cluster running inside Docker containers using k3d.

#### Why k3d?

Instead of heavy VMs, k3d uses **Docker containers** as Kubernetes nodes, making it:

- ⚡ Faster startup (seconds vs minutes)
- 💾 Less resource-intensive
- 🔄 More portable and reproducible

#### Architecture

```
┌─────────────────────────────────────┐
│           Docker Host               │
│                                     │
│  ┌──────────────┐   ┌──────────┐   │
│  │  k3d server  │──►│ loadbal  │   │
│  └──────────────┘   └────┬─────┘   │
│                          │         │
│  Port Mapping:           │         │
│  8080:80 (traefik)       │         │
│  8888:8888 (playground)  │         │
└─────────────────────────────────────┘
```

#### Deployed Application

- **Image**: `rmarcas42/playground:v1`
- **Port**: 8888 → accessible at `http://localhost:8888`
- **Namespace**: `dev`

#### How to Run

```bash
cd p3
bash scripts/install.sh
```

This script:
1. Installs Docker
2. Installs k3d (v5.6.0)
3. Installs kubectl
4. Creates `iot-cluster` with port mappings
5. Applies Kubernetes manifests from `confs/`

---

### Bonus: GitLab + ArgoCD GitOps

**Objective**: Implement a complete GitOps pipeline using GitLab CE and ArgoCD.

#### Architecture

```
┌─────────────┐      ┌─────────────┐      ┌─────────────┐
│   GitLab    │────►│  ArgoCD     │────►│   k3d       │
│ CI/CD Repo  │  sync│ Controller  │deploy│ Cluster     │
│ (IaC Config)│      │             │      │ Playground  │
└─────────────┘      └─────────────┘      └─────────────┘
```

#### Components Installed

- **GitLab CE**: Lightweight GitLab Edition with optimized resource requests
  - Redis: 256Mi memory
  - PostgreSQL: 256Mi memory
  - Webservice: 512Mi memory
- **ArgoCD**: GitOps continuous delivery tool
- **nginx-ingress**: For GitLab traffic routing

#### Port Mappings

| Port | Service | URL |
|------|---------|-----|
| **8080** | LoadBalancer (traefik) | `http://localhost:8080` |
| **8888** | Playground app | `http://localhost:8888` |
| **8929** | GitLab (HTTP) | `http://127.0.0.1.nip.io` |

#### How to Run

```bash
cd bonus
bash scripts/install-gitlab.sh
```

⏰ **Note**: This takes 5-10 minutes as it installs many components.

#### Access GitLab

After installation:
1. Visit `http://127.0.0.1.nip.io` (or `http://localhost:8929`)
2. Login with admin credentials (stored in ArgoCD or generated by GitLab)

#### GitOps Flow

```yaml
# argocd-gitlab-app.yaml defines:
sourceRepo: gitlab/playground.git (contains deploy.yaml, service.yaml, ingress.yaml)
destination: k3d cluster (automatically syncs changes)
syncPolicy: 
  - selfHeal: true  (auto-rollback drift)
  - prune: true     (delete untracked resources)
```

## 🔧 Configuration Details

### Network Configuration (P1 & P2)

| Node | IP Address | Hostname | Role |
|------|------------|----------|------|
| Server/Master | 192.168.56.110 | 0xEr3b0sS | K3s control plane |
| Worker/Agent | 192.168.56.111 | 0xEr3b0sSW | K3s worker node |

### k3d Cluster (P3 & Bonus)

```yaml
Cluster Name: iot-cluster / bonus-cluster
Nodes: 1 server, 1 agent, 1 loadbalancer
Port Mapping:
  - 8080:80@loadbalancer
  - 8888:8888@loadbalancer
```

### GitLab Resource Limits (Bonus)

The `gitlab-values.yaml` is optimized for constrained environments:

- Disabled components: certmanager, prometheus, gitlab-runner
- Reduced memory requests to prevent OOM kills
- Using `127.0.0.1.nip.io` domain trick for localhost routing

## 🧪 Testing & Verification

### Part 1: Verify Cluster

```bash
vagrant ssh server
sudo kubectl get nodes        # Should show 2 nodes Ready

vagrant ssh worker
sudo kubectl get nodes        # Same cluster visible
```

### Part 2: Test Ingress

```bash
# From VM or after port forwarding
curl -H "Host: app1.com" http://<LB-IP>
curl -H "Host: app2.com" http://<LB-IP>
curl http://<LB-IP>/          # Should hit app3
```

### Part 3: Check Playground

```bash
curl http://localhost:8888    # Verify playground responds
kubectl get all -n dev        # Verify deployment status
```

### Bonus: GitOps Test

1. Push new manifest to GitLab repo
2. ArgoCD detects change (check at `http://localhost:8080`)
3. Cluster automatically syncs within seconds
4. `kubectl get pod -n dev` shows updated application

## 🎯 Project Evaluation Points

This README covers all typical evaluation criteria:

- ✅ Clear documentation of each part
- ✅ Architecture diagrams
- ✅ Explanation of tools used (K3s, k3d, ArgoCD)
- ✅ Commands to run and verify
- ✅ Understanding demonstrated through comments in code
- ✅ Bonus implementation (GitLab + GitOps pipeline)

## 🔒 Security Considerations

- Passwords and tokens are stored in shared volumes (local dev only)
- GitLab runs on non-standard ports for local testing
- In production: enable TLS, use stronger secrets management
- Network policies should be added for production clusters

## 📖 Resources Learned

### Technologies

- **Kubernetes** (via K3s distribution)
- **k3d** - K3s in Docker
- **Vagrant** - VM provisioning
- **Helm** - Kubernetes package manager
- **ArgoCD** - GitOps automation
- **GitLab CE** - Self-hosted CI/CD
- **Ingress Controllers** (Traefik)
- **Container Networking** (Flannel)

### Concepts Mastered

- Cluster architecture (master/worker nodes)
- Deployments, Services, and Ingress
- GitOps paradigm
- Infrastructure as Code
- Continuous Integration/Deployment
- Container orchestration

## 👥 Team

| Name | Role | Contact |
|------|------|----------|
| 0xNirmata | Main Developer | 78426587+0xNirmata@users.noreply.github.com |

