FROM ubuntu:mantic-20231011
COPY src/run.sh /run.sh
RUN chmod +x /run.sh
RUN apt update
RUN apt install -y git
RUN apt-get clean

CMD /run.sh