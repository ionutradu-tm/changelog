FROM ubuntu:lunar
COPY src/run.sh /run.sh
RUN chmod +x /run.sh
RUN apt update
RUN apt install -y git
RUN apt-get clean

CMD /run.sh