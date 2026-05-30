# Server Documentation: tivieserver (Application Server)

This document describes the directory structure, user profiles, and locations of active configuration files on the main server.

## User Profiles

The server is configured with the following active user profiles under `/home/`:
*   `kristian`
*   `mathias`
*   `niko`
*   `valdemar`

All Docker projects are located centrally in the shared system directory under `/opt/`, making production files accessible across all user profiles.

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
