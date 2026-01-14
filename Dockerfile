FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV GHIDRA_HOME=/opt/ghidra
ENV JDGUI_HOME=/opt/jd-gui
ENV CARGO_HOME=/opt/cargo
ENV RUSTUP_HOME=/opt/rustup
ENV PATH=/opt/cargo/bin:$PATH

EXPOSE 8080

# -----------------------------
# System + GUI dependencies
# -----------------------------
RUN apt-get update && apt-get install -y \
    openjdk-21-jdk \
    wget \
    unzip \
    ca-certificates \
    libx11-6 \
    libxext6 \
    libxrender1 \
    libxtst6 \
    libxi6 \
    libfreetype6 \
    libgtk-3-0 \
    libxrandr2 \
    libasound2 \
    libnss3 \
    libgbm1 \
    xauth \
    less \
    groff \
    curl \
    build-essential \
    libfontconfig1-dev \
    liblzma-dev \
    pkg-config \
    git \
    libssl-dev \
    python3 \
    python3-pip \
    python3-setuptools \
    gcc \
    make \
    cmake \
    g++ \
    binutils-mips-linux-gnu \
    vim-common \
    binwalk \
    iproute2 \
    vim \
    && rm -rf /var/lib/apt/lists/*

# -----------------------------
# Download OFFICIAL Ghidra release
# (multi-platform ZIP, not source)
# -----------------------------
RUN wget -q \
    https://github.com/NationalSecurityAgency/ghidra/releases/download/Ghidra_11.3.2_build/ghidra_11.3.2_PUBLIC_20250415.zip \
    -O /tmp/ghidra.zip && \
    unzip /tmp/ghidra.zip -d /opt && \
    mv /opt/ghidra_* ${GHIDRA_HOME} && \
    rm /tmp/ghidra.zip

RUN ln -s /opt/ghidra/ghidraRun /usr/local/bin/ghidra

# -----------------------------
# Download JD-GUI
# -----------------------------
RUN mkdir -p ${JDGUI_HOME} && \
wget -q \
    https://github.com/java-decompiler/jd-gui/releases/download/v1.6.6/jd-gui-1.6.6.jar \
    -O ${JDGUI_HOME}/jd-gui.jar

RUN printf '#!/bin/sh\nexec java -jar %s/jd-gui.jar "$@"\n' "${JDGUI_HOME}" \
> /usr/local/bin/jd-gui && \
chmod +x /usr/local/bin/jd-gui

# -----------------------------
# Install AWS CLI v2
# -----------------------------
RUN wget -q https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -O /tmp/awscliv2.zip && \
unzip -q /tmp/awscliv2.zip -d /tmp && \
/tmp/aws/install && \
rm -rf /tmp/aws /tmp/awscliv2.zip

# -----------------------------
# Install Rust toolchain
# -----------------------------
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \
    | sh -s -- -y --no-modify-path

# -----------------------------
# Build Binwalk from source
# -----------------------------
RUN git clone https://github.com/ReFirmLabs/binwalk /opt/binwalk && \
cd /opt/binwalk && \
cargo build --release

RUN ln -s /opt/binwalk/target/release/binwalk /usr/local/bin/binwalk-rust

# -----------------------------
# Install python requirements
# -----------------------------
RUN python3 -m pip install --upgrade pip
RUN pip3 install --break-system-packages ubi-reader requests "mcp[cli]"

# -----------------------------
# Install tp-link-decrypt
# -----------------------------
RUN git clone https://github.com/robbins/tp-link-decrypt /opt/tp-link-decrypt
RUN chmod +x /opt/tp-link-decrypt/extract_keys.sh
RUN cd /opt/tp-link-decrypt && \
    printf "no\n" | ./extract_keys.sh
RUN make -C /opt/tp-link-decrypt -j"$(nproc)"

# -----------------------------
# Install GhidraMCP
# -----------------------------
RUN mkdir -p /opt/ghidra-mcp && \
wget -q https://github.com/LaurieWired/GhidraMCP/releases/download/1.4/GhidraMCP-release-1-4.zip \
    -O /tmp/GhidraMCP-release-1-4.zip && \
unzip -q /tmp/GhidraMCP-release-1-4.zip -d /opt/ghidra-mcp && \
rm /tmp/GhidraMCP-release-1-4.zip
RUN chmod +x /opt/ghidra-mcp/GhidraMCP-release-1-4/bridge_mcp_ghidra.py

# -----------------------------
# Create Ghidra MCP runner script
# -----------------------------
RUN printf '%s\n' \
'#!/usr/bin/env bash' \
'set -e' \
'' \
'python3 /opt/ghidra-mcp/GhidraMCP-release-1-4/bridge_mcp_ghidra.py \' \
'  --transport sse \' \
'  --mcp-host 127.0.0.1 \' \
'  --mcp-port 8081 \' \
'  --ghidra-server http://127.0.0.1:8080/' \
> /usr/local/bin/run-ghidra-mcp && \
chmod +x /usr/local/bin/run-ghidra-mcp

# -----------------------------
# Shared analysis volume
# -----------------------------
VOLUME ["/data"]

# -----------------------------
# Set entry point to shell
# -----------------------------
ENTRYPOINT ["/bin/bash"]
