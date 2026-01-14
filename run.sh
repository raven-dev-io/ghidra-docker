#!/bin/bash

IMAGE_NAME="ghidra-gui"

# Only build the image if it doesn't exist
if ! sudo docker image inspect "$IMAGE_NAME" >/dev/null 2>&1; then
    echo "[+] Docker image not found. Building $IMAGE_NAME..."
    sudo docker build -t "$IMAGE_NAME" .
else
    echo "[+] Docker image $IMAGE_NAME already exists. Skipping build."
fi

# Allow Docker to use the X server
xhost +local:docker

# Run the Docker container with Wireshark GUI
sudo docker run -it --rm \
    --env DISPLAY=$DISPLAY \
    --env QT_X11_NO_MITSHM=1 \
    --volume /tmp/.X11-unix:/tmp/.X11-unix \
    --volume /mnt/backup/docker-data:/data \
    --net=host \
    "$IMAGE_NAME"

