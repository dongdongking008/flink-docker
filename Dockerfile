# step: build flink
FROM maven:3.3-jdk-8 as flink-builder

ENV SCALA_VERSION=2.11
ENV RELEASE_VERSION=1.12.0-rc1
ENV SKIP_GPG=true
RUN mkdir /build && cd /build && git clone https://github.com/apache/flink && \
    cd flink && git checkout release-1.12.0-rc1 && \
    cd tools && releasing/create_binary_release.sh

# step: package
FROM openjdk:8-jre
LABEL maintainer="xiaodong.chen <dongdongking008@163.com>"

# Prepare environment
ENV FLINK_HOME=/opt/flink
ENV PATH=$FLINK_HOME/bin:$PATH
RUN groupadd --system --gid=9999 flink && \
    useradd --system --home-dir $FLINK_HOME --uid=9999 --gid=flink flink
WORKDIR $FLINK_HOME

# Install Flink
COPY --from=flink-builder /build/flink/tools/releasing/release/* ./

RUN chown -R flink:flink .

# Configure container
COPY docker-entrypoint.sh /
ENTRYPOINT ["/docker-entrypoint.sh"]
EXPOSE 6123 8081
CMD ["help"]
