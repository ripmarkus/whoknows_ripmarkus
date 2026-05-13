# Deployment Strategy

## Current Setup

The app runs on a single Hetzner VPS. The CD pipeline SSHs into the server, pulls the latest Docker image from GHCR, and restarts the container via Docker Compose. Migrations run automatically on startup.

The problem with this is straightforward: there is a window during `docker compose up` where the old container is down and the new one is not yet healthy. For a school project with low traffic this is acceptable, but it would not hold up in a production environment that requires high availability.

## What We Considered

### Rolling Deployments on Kubernetes

The ideal solution is a Kubernetes cluster with multiple worker nodes. Kubernetes handles rolling deployments natively - it brings up new pods before tearing down old ones, so there is no downtime window. Combined with a load balancer in front of the cluster, traffic is only routed to healthy pods.

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

This setup gives high availability (multiple control plane nodes), fault tolerance (pods are rescheduled if a node goes down), and scalability (add worker nodes as needed). It is also how production infrastructure tends to look in practice.

### Blue/Green Deployments

An alternative without Kubernetes is a blue/green setup: run two identical environments behind a load balancer and switch traffic from blue to green atomically once the new version is healthy. No downtime, easy rollback. Requires double the server resources and more orchestration work.

### Canary Releases

Route a small percentage of traffic to the new version while the majority stays on the old one. Useful for catching regressions with real traffic before a full rollout. Needs a smarter load balancer setup (e.g. nginx with upstream weighting or a service mesh).

## Decision

We are keeping Docker Compose on a single VPS for now. The Kubernetes setup described above would be the right call for a production service, but the cost of running a multi-node cluster (control plane nodes alone on Hetzner run to ~30 EUR/month) is not justified for a school project.

The current single-server setup does have one mitigation: the CD pipeline takes a database backup before every deploy, so if a bad release goes out there is always a restore point.

If this were going to production the path would be:
1. Containerise the app (already done)
2. Push images to a registry (already done - GHCR)
3. Deploy to Kubernetes with a rolling update strategy
4. Add a horizontal pod autoscaler for traffic spikes
