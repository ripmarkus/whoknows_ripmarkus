# Server Documentation: vss-vm-1 (Monitoring Server)

This document describes the directory structure, user profiles, and locations of active configuration files on the dedicated monitoring server.

## User Profiles

The server is configured with the following active user profiles under `/home/`:
*   `kristian`
*   `valdemar`
*   `mathias`
*   `niko`

All monitoring projects are located centrally in the shared system directory under `/opt/`, making production files accessible under this profile.

## Global Paths

All production files related to Docker and infrastructure monitoring are located in the main system directory under opt:
*   Path: `/opt/docker/devops/`

---

## Project Structure

### Central Monitoring Hub (whoknows_monitoring)
This directory acts as the central monitoring hub for your infrastructure. It manages the visualization stack, the metrics collection engine, and their routing configurations.

*   Path: `/opt/docker/devops/whoknows_monitoring/`
*   Key Directories and Files:
    *   `compose.yaml` — The primary Docker Compose file that spins up Prometheus, Grafana, and the local monitoring stack.
    *   `prometheus/` — Contains the configuration rules (`prometheus.yml`) detailing which external targets and metrics endpoints to scrape.
    *   `grafana/` — Stores data persistence layers, dashboards, and analytical data visualization settings.
    *   `nginx/` — Handles reverse proxy logic specific to routing internal traffic to the monitoring dashboards.
    *   `PLAN.md` & `README.md` — Project planning and architecture documentation for the monitoring stack.

---

## Navigation Shortcuts

Use these absolute paths to jump directly to the relevant areas on the server.

Go directly to the central monitoring stack deployment files:

```bash
cd /opt/docker/devops/whoknows_monitoring/
```
