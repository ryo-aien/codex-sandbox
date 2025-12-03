FROM ubuntu:22.04

ARG USER_NAME=dev
ARG USER_UID=1000
ARG USER_GID=1000
ARG CODEX_INSTALL_CMD="npm install -g @openai/codex"

ENV DEBIAN_FRONTEND=noninteractive \
    NPM_CONFIG_PREFIX="/home/${USER_NAME}/.npm-global" \
    PATH="/home/${USER_NAME}/.npm-global/bin:/home/${USER_NAME}/.local/bin:${PATH}"

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        bash \
        ca-certificates \
        curl \
        git \
        gnupg \
        python3 \
        python3-pip \
    && curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && rm -rf /var/lib/apt/lists/*

RUN groupadd --gid "${USER_GID}" "${USER_NAME}" \
    && useradd --uid "${USER_UID}" --gid "${USER_GID}" -m "${USER_NAME}" \
    && echo "${USER_NAME} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${USER_NAME} \
    && chmod 0440 /etc/sudoers.d/${USER_NAME} \
    && mkdir -p "/home/${USER_NAME}/.npm-global" "/home/${USER_NAME}/.codex" \
    && chown -R "${USER_UID}:${USER_GID}" "/home/${USER_NAME}/.npm-global" "/home/${USER_NAME}/.codex"

WORKDIR /workspace

COPY scripts/install-codex.sh /usr/local/bin/install-codex
RUN chmod +x /usr/local/bin/install-codex

USER ${USER_NAME}

RUN if [ -n "${CODEX_INSTALL_CMD}" ] || [ -f "/workspace/bin/codex" ]; then \
      CODEX_INSTALL_CMD="${CODEX_INSTALL_CMD}" install-codex; \
    else \
      echo "[install-codex] Skipped during build (no CODEX_INSTALL_CMD or /workspace/bin/codex)."; \
    fi

CMD ["/bin/bash"]
