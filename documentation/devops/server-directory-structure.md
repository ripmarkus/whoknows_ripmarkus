# Server Documentation: tivieserver (Application Server)

This document describes the directory structure and locations of active configuration files on the main server.

## Architecture Philosophy

All Docker and deployment structures are strictly isolated inside the `/opt/` system directory using the following conventions:

*   **System Decoupling:** Keeping configurations entirely out of individual `/home/` directories ensures that files remain accessible and persistent regardless of which team member is logged in.
*   **Centralized Backup Scope:** Consolidating all infrastructure configurations inside a single root directory (`/opt/docker/devops/`) allows for simple, unified snapshotting and disaster recovery.
*   **FHS Compliance:** Adhering to the standard Linux Filesystem Hierarchy Standard by placing self-contained, optional third-party stacks into the global `/opt/` space.


## Global Paths

All active production files related to Docker and server management are located in the main system directory under opt:

*   Path: `/opt/docker/devops/`

---

## Project Structure

### Ruby Application, Node Exporter & Nginx Proxy
This directory is the central hub of the server. It contains the source code, database, web server, and the monitoring agent (Node Exporter). Everything runs within a closed, internal Docker network under this shared configuration.

*   Path: `/opt/docker/devops/whoknows_ripmarkus/ruby-app/`
*   Key Files:
    *   `compose.yaml` — The active Docker Compose file managing the database, Ruby app, Nginx, and the active Node Exporter.
    *   `nginx.conf` — The web server configuration file handling the domain, SSL certificates, and secure endpoints (`/metrics/ruby` and `/metrics/node`) for external monitoring.
    *   `Dockerfile` — The recipe file used to build the internal Ruby application environment.

---

## Navigation Shortcuts

Use these absolute paths to jump directly to the relevant areas on the server.

Go directly to the active configuration files for the entire setup:
```bash
cd /opt/docker/devops/whoknows_ripmarkus/ruby-app/
```
