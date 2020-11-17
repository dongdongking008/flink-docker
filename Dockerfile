# step: build flink
FROM openjdk:11-jdk as flink-builder

RUN MAVEN_VERSION=3.2.5 USER_HOME_DIR=/root /bin/sh -c "mkdir -p /usr/share/maven /usr/share/maven/ref /root/.m2" && \
    curl -fsSL https://archive.apache.org/dist/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz |\
    tar -xzC /usr/share/maven --strip-components=1 && ln -s /usr/share/maven/bin/mvn /usr/bin/mvn
ENV MAVEN_HOME=/usr/share/maven
ENV MAVEN_CONFIG=/root/.m2

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
