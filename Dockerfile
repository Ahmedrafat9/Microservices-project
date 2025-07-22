FROM snyk/snyk:docker

# Install Java
RUN apt-get update && apt-get install -y openjdk-11-jdk

# Install Go
RUN wget https://go.dev/dl/go1.21.0.linux-amd64.tar.gz && \
    tar -C /usr/local -xzf go1.21.0.linux-amd64.tar.gz && \
    rm go1.23.1.linux-amd64.tar.gz

# Install Python (usually already available)
RUN apt-get install -y python3 python3-pip

# Set environment variables
ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
ENV PATH=$PATH:/usr/local/go/bin
ENV PATH=$PATH:$JAVA_HOME/bin

WORKDIR /app