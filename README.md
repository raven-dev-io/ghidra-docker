# Ghidra GUI + MCP Docker Container

This repository provides a Dockerized reverse‑engineering environment centered around Ghidra, with additional tooling for firmware analysis, Java decompilation, AI MCP (Model Context Protocol) bridging, and proxy/server workflows.

The container is designed to:
- Run Ghidra with a native GUI via X11
- Host a Ghidra MCP bridge for MCP server/proxy integration
- Provide a reproducible RE environment
- Support firmware, embedded, and malware analysis workflows

This setup intentionally trades Docker isolation for tight host‑network integration, which is required for MCP and proxy use cases.

---

## What This Is

- A GUI‑enabled Docker container for Ghidra
- Includes common reverse‑engineering and firmware analysis tooling
- Supports MCP server + proxy workflows via host networking
- Uses host X11 forwarding for native GUI applications

This is not a minimal container. It is intended to function as an AI-assisted analyst workstation.

---

## Host Dependencies (Required)

These must be installed on the host system:

- Docker Engine (docker / docker.io)
- Linux host
- X11 display server (Xorg recommended)
- xhost
- Internet access (required at build time)

macOS and Windows are not supported without significant changes (XQuartz / WSLg).

---

## Security & Trust Model

This container:
- Uses host networking (--net=host)
- May require NET_ADMIN, NET_RAW, or /dev/net/tun for MCP/proxy workflows
- Interacts directly with the host network stack

Do NOT run this on untrusted systems.
Do NOT expose services externally unless you understand the risk.

This setup is intended for local analysis only.

---

## Build Instructions

A build script is provided:

build.sh:
sudo docker build -t ghidra-gui .

To build manually:
sudo docker build -t ghidra-gui .

The build process:
- Downloads the official Ghidra release
- Installs reverse‑engineering and firmware tooling
- Sets up Ghidra MCP integration
- Prepares the container for GUI execution

---

## Run Instructions

The run script:
- Builds the image if it does not exist
- Grants X11 access to Docker
- Runs the container with host networking

run.sh:
IMAGE_NAME="ghidra-gui"

If the image does not exist, it will be built automatically.

The container is run with:
- DISPLAY forwarded from host
- X11 socket mounted
- Shared /data volume
- Host networking enabled

Run with:
./run.sh

NOTE: you will need to change the shared data path in the run.sh command to match a real path in your system.

If GUI permissions fail, run on the host:
xhost +local:docker

---

## GUI Notes

- Uses X11 forwarding (not VNC or web UI)
- Requires a running X server
- Wayland may work via XWayland but is not guaranteed

---

## Tools Included

Reverse Engineering:
- Ghidra (official release)
- Ghidra MCP plugin
- JD‑GUI (Java decompiler)

Firmware / Embedded Analysis:
- Binwalk (Rust build)
- Binwalk (c build)
- ubi-reader
- tp-link-decrypt
- Embedded firmware tooling
- squashfs-tools
- unyaffs
- firmware-utils
- firmware-mod-kit

Model Context Protocol:
- GhidraMCP bridge
- MCP server integration
- SSE transport support

Development / Scripting:
- Python 3
- Rust toolchain
- Git and build utilities

---

## MCP Integration

The container includes a helper script:
run-ghidra-mcp

This starts the Ghidra MCP bridge using:
- SSE transport
- MCP server at 127.0.0.1:8081
- Ghidra server at 127.0.0.1:8080

This assumes:
- MCP server/proxy is reachable via host networking
- Ghidra is running inside the container

---

## Data Persistence

A shared volume is mounted at:
/data

Use this for:
- Firmware images
- Binaries
- Ghidra projects
- Analysis artifacts

---

## Intended Use Cases

- Malware reverse engineering
- Firmware and embedded analysis
- Ghidra automation via MCP
- C2 simulation and proxy workflows
- Reproducible RE environments

---

## What This Is Not

- A hardened sandbox
- A cloud‑safe deployment
- A minimal image
- A replacement for full VM isolation

---

## Notes

- The image is intentionally large and feature‑rich
- Updates require rebuilding the image
- Host networking is required for MCP functionality

