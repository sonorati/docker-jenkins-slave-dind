FROM docker:18.02

MAINTAINER Viktor Farcic <viktor@farcic.com>

ARG version="0.2.0"
ARG build_date="unknown"
ARG commit_hash="unknown"
ARG vcs_url="unknown"
ARG vcs_branch="unknown"

LABEL org.label-schema.vendor="vfarcic" \
    org.label-schema.name="jenkins-swarm-agent" \
    org.label-schema.description="Jenkins agent based on the Swarm plugin" \
    org.label-schema.usage="/src/README.md" \
    org.label-schema.url="https://github.com/vfarcic/docker-jenkins-slave-dind/blob/master/README.md" \
    org.label-schema.vcs-url=$vcs_url \
    org.label-schema.vcs-branch=$vcs_branch \
    org.label-schema.vcs-ref=$commit_hash \
    org.label-schema.version=$version \
    org.label-schema.schema-version="1.0" \
    org.label-schema.build-date=$build_date

ENV SWARM_CLIENT_VERSION="3.9" \
    DOCKER_COMPOSE_VERSION="1.19.0" \
    COMMAND_OPTIONS="" \
    USER_NAME_SECRET="" \
    PASSWORD_SECRET=""  \
    LANG="C.UTF-8"

RUN adduser -G root -D jenkins && \
    apk --update --no-cache add openjdk8 python py-pip git openssh ca-certificates openssl && \
    wget -q https://repo.jenkins-ci.org/releases/org/jenkins-ci/plugins/swarm-client/${SWARM_CLIENT_VERSION}/swarm-client-${SWARM_CLIENT_VERSION}.jar -P /home/jenkins/ && \
    pip install docker-compose


# add a simple script that can auto-detect the appropriate JAVA_HOME value
# based on whether the JDK or only the JRE is installed
RUN { \
		echo '#!/bin/sh'; \
		echo 'set -e'; \
		echo; \
		echo 'dirname "$(dirname "$(readlink -f "$(which javac || which java)")")"'; \
	} > /usr/local/bin/docker-java-home \
	&& chmod +x /usr/local/bin/docker-java-home
ENV JAVA_HOME /usr/lib/jvm/java-1.8-openjdk
ENV PATH $PATH:/usr/lib/jvm/java-1.8-openjdk/jre/bin:/usr/lib/jvm/java-1.8-openjdk/bin

ENV JAVA_VERSION 8u151
ENV JAVA_ALPINE_VERSION 8.151.12-r0

RUN set -x \
	&& apk add --no-cache \
		openjdk8="$JAVA_ALPINE_VERSION" \
	&& [ "$JAVA_HOME" = "$(docker-java-home)" ]


RUN mkdir -p /opt/maven ; cd /opt/maven ; wget -O - http://mirrors.ukfast.co.uk/sites/ftp.apache.org/maven/maven-3/3.5.3/binaries/apache-maven-3.5.3-bin.tar.gz | tar zxf -
RUN ln -s /opt/maven/apache-maven-3.5.3/bin/mvn /usr/bin
ENV MAVEN_HOME /opt/maven

COPY run.sh /run.sh
RUN chmod +x /run.sh

CMD ["/run.sh"]
