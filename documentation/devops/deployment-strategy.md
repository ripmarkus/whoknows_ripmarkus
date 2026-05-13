# Deployment Strategy

## Current Setup

The app runs on a home server. A separate Hetzner VPS hosts the monitoring stack (Grafana, Prometheus). The CD pipeline SSHs into the home server, pulls the latest Docker image from GHCR, and restarts the container via Docker Compose. Migrations run automatically on startup.

The problem with this is straightforward: there is a window during `docker compose up` where the old container is down and the new one is not yet healthy. For a project with low traffic this is acceptable, but it would not hold up in a production environment that requires high availability.

## What We Considered

### GitOps with a Separate Infra Repo

Rather than having the application repo trigger deployments directly, a cleaner model is to split concerns into two repos:

- **App repo** (this repo) - builds and publishes a versioned Docker image to GHCR on every merge to main
- **Infra repo** - owns the deployment manifests and is the only thing that talks to the server

The infra repo watches for new image versions (e.g. via Renovate or a version-bump bot) and opens a PR automatically when a new image is published. Merging that PR triggers the actual deploy. This means:

- Deployments are always tied to an explicit, reviewable change in the infra repo
- Rolling back is a revert commit, not a manual SSH command
- The app repo has no credentials for the production server

This is the GitOps model and is how tools like ArgoCD and Flux work on Kubernetes, but the same principle applies with Docker Compose on a single server.

### Rolling Deployments on Kubernetes

The further step up is a Kubernetes cluster with multiple worker nodes. Kubernetes handles rolling deployments natively - it brings up new pods before tearing down old ones, so there is no downtime window. Combined with a load balancer in front of the cluster, traffic is only routed to healthy pods.

One of us has built exactly this kind of infrastructure privately: a bare-metal Kubernetes cluster on Hetzner using Talos Linux, with three control plane nodes, worker nodes, a NAT gateway for outbound traffic, and a load balancer as the only public entry point. None of the nodes are reachable directly from the internet.

```
Internet -> Load Balancer (public IP)
                |
         Private Network (10.0.0.0/16)
         |- nat-vm   - outbound NAT gateway
         |- cp1      - control plane
         |- cp2      - control plane
         |- cp3      - control plane
         |- worker1  - worker node
```

This setup gives high availability (multiple control plane nodes), fault tolerance (pods are rescheduled if a node goes down), and scalability (add worker nodes as needed).

### Blue/Green Deployments

Run two identical environments behind a load balancer and switch traffic from blue to green atomically once the new version is healthy. No downtime, easy rollback. Requires double the server resources and more orchestration work.

### Canary Releases

Route a small percentage of traffic to the new version while the majority stays on the old one. Useful for catching regressions with real traffic before a full rollout. Needs a smarter load balancer setup (e.g. nginx with upstream weighting or a service mesh).

## Decision

We are keeping Docker Compose on the home server for now. The cost of running a multi-node Kubernetes cluster is not justified for a school project.

The GitOps split (separate infra repo, deploy only on version bump) is the improvement we would prioritise first - it is low cost to set up and gives a much cleaner audit trail for deployments without requiring new infrastructure.

The current setup does have one mitigation: the CD pipeline takes a database backup before every deploy, so if a bad release goes out there is always a restore point.

If this were going to production the path would be:
1. Containerise the app (already done)
2. Push versioned images to a registry (already done - GHCR)
3. Move to a GitOps model with a dedicated infra repo
4. Deploy to Kubernetes with a rolling update strategy
5. Add a horizontal pod autoscaler for traffic spikes
