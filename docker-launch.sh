make#!/bin/bash

# DevSeizan Docker Launcher
# https://github.com/dev-seizan/devseizan

BASE_DIR=$(realpath "$(dirname "$BASH_SOURCE")")

if [[ ! -d "$BASE_DIR/auth" ]]; then
    echo "Creating auth directory..."
    mkdir -p "$BASE_DIR/auth"
fi

CONTAINER="devseizan"
IMAGE="devseizan/devseizan:latest"
MOUNT_LOCATION="${BASE_DIR}/auth"

check_container=$(docker ps --all --format "{{.Names}}" | grep -w "$CONTAINER")

if [[ -z "$check_container" ]]; then
    echo "Creating new container..."
    docker create \
        --interactive --tty \
        --volume "${MOUNT_LOCATION}:/devseizan/auth/" \
        --network host \
        --name "${CONTAINER}" \
        "${IMAGE}"
fi

docker start --interactive "${CONTAINER}"