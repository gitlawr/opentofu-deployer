FROM --platform=$TARGETPLATFORM alpine:3.17.3

ARG TARGETPLATFORM
ARG TARGETOS
ARG TARGETARCH

RUN set -eo pipefail; \
    apk add -U --no-cache \
      ca-certificates \
      curl unzip git bash openssh jq \
    ; \
    rm -rf /var/cache/apk/*;

# set locale
RUN set -eo pipefail; \
    apk add -U --no-cache \
      tzdata \
    ; \
    rm -rf /var/cache/apk/*;
ENV LANG='en_US.UTF-8' \
    LANGUAGE='en_US:en' \
    LC_ALL='en_US.UTF-8'


# get kubectl
RUN KUBECTL_VER="v1.28.4"; \
    curl -sfL https://dl.k8s.io/${KUBECTL_VER}/kubernetes-client-${TARGETOS}-${TARGETARCH}.tar.gz | \
        tar -xvzf - --strip-components=3 --no-same-owner -C /usr/bin/ kubernetes/client/bin/kubectl && \
    ln -s /usr/bin/kubectl /usr/bin/k

# get OpenTofu
RUN TOFU_VER="1.6.0-alpha5"; \
    curl -sfL https://github.com/opentofu/opentofu/releases/download/v${TOFU_VER}/tofu_${TOFU_VER}_${TARGETOS}_${TARGETARCH}.zip -o /tmp/tofu.zip && \
    unzip /tmp/tofu.zip -d /usr/bin/ && \
    ln -s /usr/bin/tofu /usr/bin/terraform; \
    \
    rm -f /tmp/tofu.zip
ENV TF_LOG=INFO

# run as non-root
RUN adduser -D -h /var/terraform -u 1000 terraform
USER terraform
WORKDIR /var/terraform/workspace

RUN mkdir -p /var/terraform/.terraform.d/plugins

# prepare provider plugin mirror for built-in templates
COPY mirror-plugins.sh .
RUN ./mirror-plugins.sh

# Prepare .terraformrc
COPY terraformrc /var/terraform/.terraformrc

CMD [ "terraform" ]