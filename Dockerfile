# Stage 1: Download kubectl in a temporary image
FROM debian:stable-slim as kubectl-builder

ARG KUBECTL_VERSION="latest"

RUN apt-get update && apt-get install -y --no-install-recommends curl ca-certificates \
    && update-ca-certificates \
    && curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" \
    && curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256" \
    && echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check \
    && chmod +x kubectl


# Stage 2: Use official Vault image and copy only necessary binaries
FROM hashicorp/vault:latest

# Install bash and jq only, keeping the image lightweight
RUN apk add --no-cache bash jq

# Copy kubectl binary from the builder stage
COPY --from=kubectl-builder /kubectl /usr/local/bin/kubectl

# Set working directory to Vault default
WORKDIR /vault

# Verify installations
RUN vault --version \
    && kubectl version --client --output=yaml \
    && jq --version

# Metadata
LABEL maintainer="Philip Solarz <philipsolarz@outlook.com>" \
    description="Vault container with kubectl and jq installed"

# Set bash as the default shell
ENTRYPOINT ["/bin/bash"]
