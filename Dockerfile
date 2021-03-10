# First build the dempo application fat jar (java application)
FROM maven:3.6-jdk-11 AS java-builder

WORKDIR /usr/src/mymaven
COPY demo-app/ .

RUN mvn clean package

# Create the image where we run circusd
FROM debian:buster

RUN DEBIAN_FRONTEND=noninteractive apt-get update -y && \
    apt-get install -y wget apt-transport-https gnupg python3 python3-pip vim

ENV CODENAME buster
RUN export CODENAME=$(cat /etc/os-release | grep VERSION_CODENAME | cut -d = -f 2)
RUN wget -qO - https://adoptopenjdk.jfrog.io/adoptopenjdk/api/gpg/key/public | apt-key add -
RUN echo "deb https://adoptopenjdk.jfrog.io/adoptopenjdk/deb ${CODENAME} main" | tee /etc/apt/sources.list.d/adoptopenjdk.list

RUN apt-get update -y && \
    apt-get install -y adoptopenjdk-11-hotspot

RUN pip3 install circus==0.17.1

RUN mkdir -p /var/log/circus
RUN mkdir -p /etc/circus/conf.d
RUN mkdir -p /srv/mine/app1/log
RUN mkdir -p /srv/mine/app2/log
RUN mkdir -p /srv/mine/app3/log
RUN mkdir -p /srv/mine/app4/log

COPY --from=java-builder /usr/src/mymaven/target/demo-0.0.1-SNAPSHOT.jar /srv/mine/app1/demo1.jar
COPY --from=java-builder /usr/src/mymaven/target/demo-0.0.1-SNAPSHOT.jar /srv/mine/app2/demo2.jar
COPY --from=java-builder /usr/src/mymaven/target/demo-0.0.1-SNAPSHOT.jar /srv/mine/app3/demo3.jar
COPY --from=java-builder /usr/src/mymaven/target/demo-0.0.1-SNAPSHOT.jar /srv/mine/app4/demo4.jar

COPY config/circusd.ini /etc/circus/
COPY config/logback.xml /etc/circus/
COPY config/app1.ini /etc/circus/conf.d
COPY config/app2.ini /etc/circus/conf.d
COPY config/app3.ini /etc/circus/conf.d
COPY config/app4.ini /etc/circus/conf.d

CMD [ "/usr/bin/python3", "/usr/local/bin/circusd", "/etc/circus/circusd.ini" ]
