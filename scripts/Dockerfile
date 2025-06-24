# Dockerfile
FROM mcr.microsoft.com/devcontainers/base:ubuntu

# Install all required tools
RUN apt-get update && apt-get install -y \
    ca-certificates curl gnupg lsb-release wget jq \
    && rm -rf /var/lib/apt/lists/*

# Install Docker
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null \
    && apt-get update \
    && apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin \
    && rm -rf /var/lib/apt/lists/*

# Install k3d
RUN curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

# Install kubectl
RUN curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg \
    && chmod 644 /etc/apt/keyrings/kubernetes-apt-keyring.gpg \
    && echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' | tee /etc/apt/sources.list.d/kubernetes.list \
    && apt-get update \
    && apt-get install -y kubectl \
    && rm -rf /var/lib/apt/lists/*

# Install Helm (for potential Dapr pre-installation)
RUN curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Install crane for downloading container images without Docker daemon
RUN wget -qO- https://api.github.com/repos/google/go-containerregistry/releases/latest | \
    grep "browser_download_url.*Linux_$(uname -m | sed 's/aarch64/arm64/;s/x86_64/x86_64/').tar.gz" | \
    cut -d '"' -f 4 | \
    xargs curl -L | \
    tar xz -C /usr/local/bin crane

# Install Drasi CLI
RUN curl -fsSL https://raw.githubusercontent.com/drasi-project/drasi-platform/main/cli/installers/install-drasi-cli.sh | bash

# Pre-download Drasi images for the current build platform
ARG TARGETPLATFORM
ENV DRASI_VERSION=0.3.4
RUN mkdir -p /opt/drasi-images && \
    echo "Pre-downloading Drasi images for platform ${TARGETPLATFORM}..." && \
    images="api kubernetes-provider \
    query-container-query-host query-container-publish-api query-container-view-svc \
    source-change-router source-change-dispatcher source-query-api \
    source-debezium-reactivator source-sql-proxy \
    source-cosmosdb-reactivator source-gremlin-proxy \
    source-dataverse-reactivator source-dataverse-proxy \
    source-eventhub-reactivator source-eventhub-proxy \
    source-kubernetes-reactivator source-kubernetes-proxy \
    reaction-signalr reaction-dataverse reaction-debezium \
    reaction-debug reaction-eventgrid reaction-eventbridge \
    reaction-gremlin reaction-result reaction-storage-queue \
    reaction-sync-dapr-statestore reaction-post-dapr-pubsub reaction-storedproc" && \
    for img in $images; do \
        echo "Downloading ghcr.io/drasi-project/$img:$DRASI_VERSION for ${TARGETPLATFORM}..." && \
        crane pull --platform=${TARGETPLATFORM} ghcr.io/drasi-project/$img:$DRASI_VERSION /opt/drasi-images/$img.tar || echo "Failed to download $img"; \
    done && \
    echo "Downloaded $(ls /opt/drasi-images/*.tar 2>/dev/null | wc -l) Drasi images"

# Pre-download Dapr images for the current build platform
RUN mkdir -p /opt/dapr-images && \
    echo "Pre-downloading Dapr images for platform ${TARGETPLATFORM}..." && \
    images="daprio/dapr:1.10.0 \
    daprio/dashboard:0.12.0 \
    daprio/sentry:1.10.0 \
    daprio/placement:1.10.0 \
    daprio/dapr-operator:1.10.0 \
    daprio/daprd:1.9.0" && \
    for img in $images; do \
        echo "Downloading $img for ${TARGETPLATFORM}..." && \
        crane pull --platform=${TARGETPLATFORM} $img /opt/dapr-images/$(echo $img | tr '/:' '_').tar || echo "Failed to download $img"; \
    done && \
    echo "Downloaded $(ls /opt/dapr-images/*.tar 2>/dev/null | wc -l) Dapr images"

# Pre-download k3s image for the current build platform
RUN mkdir -p /opt/k3s-images && \
    echo "Pre-downloading k3s image for platform ${TARGETPLATFORM}..." && \
    crane pull --platform=${TARGETPLATFORM} rancher/k3s:v1.31.4-k3s1 /opt/k3s-images/k3s.tar || echo "Failed to download k3s"

# Create optimized initialization script
RUN echo '#!/bin/bash\n\
set -e\n\
\n\
echo "=== Fast Drasi DevContainer Initialization ==="\n\
echo "Pre-cached images will be used to avoid downloads"\n\
\n\
# Start Docker if not running\n\
if ! docker info >/dev/null 2>&1; then\n\
    echo "Starting Docker daemon..."\n\
    sudo service docker start\n\
    sleep 2\n\
fi\n\
\n\
# Load all pre-cached images in parallel\n\
echo "Loading pre-cached images into Docker..."\n\
(\n\
    ls /opt/drasi-images/*.tar 2>/dev/null | xargs -P 10 -I {} docker load -i {} >/dev/null 2>&1 &\n\
    ls /opt/dapr-images/*.tar 2>/dev/null | xargs -P 10 -I {} docker load -i {} >/dev/null 2>&1 &\n\
    ls /opt/k3s-images/*.tar 2>/dev/null | xargs -P 10 -I {} docker load -i {} >/dev/null 2>&1 &\n\
    wait\n\
)\n\
echo "Images loaded"\n\
\n\
# Create k3d cluster\n\
echo "Creating k3d cluster..."\n\
k3d cluster create devcluster \\\n\
    --port "80:80@loadbalancer" \\\n\
    --k3s-arg "--disable=traefik@server:0" \\\n\
    --k3s-arg "--disable=metrics-server@server:0" \\\n\
    --wait\n\
\n\
# Import all images into k3d cluster\n\
echo "Importing images into k3d cluster..."\n\
docker images --format "{{.Repository}}:{{.Tag}}" | grep -E "(drasi-project|daprio|rancher/k3s)" | \\\n\
    xargs -P 20 -I {} k3d image import {} -c devcluster >/dev/null 2>&1\n\
\n\
# Initialize Drasi with local images\n\
echo "Initializing Drasi (using local images, no downloads needed)..."\n\
drasi init --local --version '$DRASI_VERSION'\n\
\n\
echo "=== Drasi platform ready! ==="\n\
' > /usr/local/bin/drasi-fast-init.sh && chmod +x /usr/local/bin/drasi-fast-init.sh

# The devcontainer base image already has vscode user, just add to docker group
RUN usermod -aG docker vscode

# Set environment variables
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# Set ownership of downloaded images (only for directories that exist)
RUN for dir in /opt/drasi-images /opt/dapr-images /opt/k3s-images; do \
        if [ -d "$dir" ]; then \
            chown -R vscode:vscode "$dir"; \
        fi; \
    done

USER vscode
WORKDIR /home/vscode