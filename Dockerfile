# Stage 1: Download and install kubectl
FROM debian:stable-slim as kubectl-builder

ARG KUBECTL_VERSION="latest"
RUN apt-get update && apt-get install -y bash curl jq \
    && if [ "$KUBECTL_VERSION" = "latest" ]; then \
    KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt); \
    fi \
    && curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl" \
    && chmod +x kubectl

# Stage 2: Build final image based on Vault
FROM hashicorp/vault:latest

# Copy kubectl from the previous stage
COPY --from=kubectl-builder /kubectl /usr/local/bin/kubectl

# Set correct permissions
RUN chmod +x /usr/local/bin/kubectl \
    && vault --version \
    && kubectl version --client

# Set working directory to Vault default
WORKDIR /vault

# Entrypoint script to run both Vault and allow direct CLI access
ENTRYPOINT ["/bin/bash"]
