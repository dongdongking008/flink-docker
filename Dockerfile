# step: build flink
FROM dongdongking008/flink-builder as flink-builder

ENV SCALA_VERSION=2.11
ENV RELEASE_VERSION=1.12.0
RUN mkdir /build && cd /build && git clone https://github.com/apache/flink && \
    cd flink && git checkout release-1.12.0-rc1
RUN cd /build/flink &&\
    mvn clean package -Dscala-2.11 -Prelease -pl flink-dist -am -Dgpg.skip -Dcheckstyle.skip=true -DskipTests &&\
    cd flink-dist/target/flink-${RELEASE_VERSION}-bin &&\
    /build/flink/tools/releasing/collect_license_files.sh ./flink-${RELEASE_VERSION} ./flink-${RELEASE_VERSION}

ENV FLINK_HOME=/opt/flink
RUN groupadd --system --gid=9999 flink && \
    useradd --system --home-dir $FLINK_HOME --uid=9999 --gid=flink flink
    
RUN cd /build/flink/flink-dist/target/flink-1.12.0-bin/flink-1.12.0 &&\
    chown -R flink:flink .

# step: package
FROM openjdk:8-jre
LABEL maintainer="xiaodong.chen <dongdongking008@163.com>"

# Install dependencies
RUN set -ex; \
  apt-get update; \
  apt-get -y install libsnappy1v5 gettext-base; \
  rm -rf /var/lib/apt/lists/*

# Grab gosu for easy step-down from root
ENV GOSU_VERSION 1.11
RUN set -ex; \
  wget -nv -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture)"; \
  wget -nv -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture).asc"; \
  export GNUPGHOME="$(mktemp -d)"; \
  for server in ha.pool.sks-keyservers.net $(shuf -e \
                          hkp://p80.pool.sks-keyservers.net:80 \
                          keyserver.ubuntu.com \
                          hkp://keyserver.ubuntu.com:80 \
                          pgp.mit.edu) ; do \
      gpg --batch --keyserver "$server" --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 && break || : ; \
  done && \
  gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu; \
  gpgconf --kill all; \
  rm -rf "$GNUPGHOME" /usr/local/bin/gosu.asc; \
  chmod +x /usr/local/bin/gosu; \
  gosu nobody true

# Prepare environment
ENV FLINK_HOME=/opt/flink
ENV PATH=$FLINK_HOME/bin:$PATH
RUN groupadd --system --gid=9999 flink && \
    useradd --system --home-dir $FLINK_HOME --uid=9999 --gid=flink flink
WORKDIR $FLINK_HOME

# Install Flink
COPY --from=flink-builder /build/flink/flink-dist/target/flink-1.12.0-bin/flink-1.12.0 ./

# Configure container
COPY docker-entrypoint.sh /
ENTRYPOINT ["/docker-entrypoint.sh"]
EXPOSE 6123 8081
CMD ["help"]
