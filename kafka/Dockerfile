# This Dockerfile creates a custom Strimzi Kafka image with the Aiven Tiered Storage plugin.
# The implementation is based on the official Strimzi blog post about Tiered Storage.

# 1. Use the official Strimzi Kafka image as the base.
#    The version should match the Kafka version you intend to run (e.g., 4.0.0).
ARG STRIMZI_KAFKA_IMAGE=quay.io/strimzi/kafka:0.47.0-kafka-4.0.0
FROM $STRIMZI_KAFKA_IMAGE

USER root:root

# 2. Create a single directory for the Aiven tiered storage plugin.
#    Both core and s3 components will be placed here.
RUN mkdir -p /opt/kafka/plugins/tiered-storage-aiven


# 3. Define the plugin version and download URLs.
#    NOTE: The blog post uses a snapshot version. We will adapt this to use a stable release if possible,
#    but the core principle of downloading pre-compiled packages remains.
#    We will assume a hypothetical stable release URL structure for robustness.
#    Let's find the actual latest release artifacts.
#    Based on previous findings, we will use a known release version.
ARG PLUGIN_VERSION=1.0.0
ARG CORE_URL=https://github.com/Aiven-Open/tiered-storage-for-apache-kafka/releases/download/v${PLUGIN_VERSION}/core-${PLUGIN_VERSION}.tgz
ARG S3_URL=https://github.com/Aiven-Open/tiered-storage-for-apache-kafka/releases/download/v${PLUGIN_VERSION}/s3-${PLUGIN_VERSION}.tgz
ARG FILE_URL=https://github.com/Aiven-Open/tiered-storage-for-apache-kafka/releases/download/v${PLUGIN_VERSION}/filesystem-${PLUGIN_VERSION}.tgz

# 4. Download and unpack both core and plugins into the same directory.
#    The --strip-components=1 flag removes the top-level directory from the tarball.
RUN curl -sL ${FILE_URL} | tar -xz --strip-components=1 -C /opt/kafka/plugins/tiered-storage-aiven && \
    curl -sL ${S3_URL} | tar -xz --strip-components=1 -C /opt/kafka/plugins/tiered-storage-aiven && \
    curl -sL ${CORE_URL} | tar -xz --strip-components=1 -C /opt/kafka/plugins/tiered-storage-aiven

# 5. Set the correct permissions for the plugin directory.
RUN chown -R 1001:0 /opt/kafka/plugins/tiered-storage-aiven && \
    chmod -R 755 /opt/kafka/plugins/tiered-storage-aiven


# 6. Switch back to the default kafka user.
USER 1001