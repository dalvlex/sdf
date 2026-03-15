FROM node:20-bookworm

# System dependencies: git, python, cypress deps, common tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    jq \
    sudo \
    python3 \
    python3-pip \
    python3-venv \
    # Cypress system dependencies
    libgtk2.0-0 \
    libgtk-3-0 \
    libgbm-dev \
    libnotify-dev \
    libnss3 \
    libxss1 \
    libasound2 \
    libxtst6 \
    xauth \
    xvfb \
    # Useful extras
    ripgrep \
    openssh-client \
    && rm -rf /var/lib/apt/lists/*

# Give node user sudo access (no password)
RUN echo "node ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Install Claude Code (native installer as node user)
USER node
RUN curl -fsSL https://claude.ai/install.sh | bash
ENV PATH="/home/node/.local/bin:${PATH}"
USER root

# Install project-specific packages if packages.txt is provided
COPY packages.txt /tmp/packages.txt
RUN if [ -s /tmp/packages.txt ]; then \
    apt-get update && xargs -a /tmp/packages.txt apt-get install -y --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*; \
    fi

# afplay shim: relays sound requests to host macOS via shared dir
RUN printf '#!/bin/sh\necho "$1" > "/tmp/sound-relay/play-$$" 2>/dev/null\nexit 0\n' > /usr/local/bin/afplay \
    && chmod +x /usr/local/bin/afplay

# Switch to non-root user
USER node

# Alias for running Claude with full permissions
RUN echo 'alias claude-sudo="claude --dangerously-skip-permissions"' >> /home/node/.bashrc

# Disable auto-updater in container
ENV DISABLE_AUTOUPDATER=1

CMD ["bash"]
