FROM debian:10-slim AS donwload-samtools
RUN apt-get update && apt-get install -y curl bzip2 && rm -rf /var/lib/apt/lists/*
RUN curl -OL https://github.com/samtools/samtools/releases/download/1.10/samtools-1.10.tar.bz2
RUN tar xjf samtools-1.10.tar.bz2

FROM debian:10-slim AS samtools-build
RUN apt-get update && apt-get install -y libssl-dev libncurses-dev build-essential zlib1g-dev liblzma-dev libbz2-dev curl libcurl4-openssl-dev
COPY --from=donwload-samtools /samtools-1.10 /build
WORKDIR /build
RUN ./configure && make -j4 && make install

FROM debian:10-slim AS download-bowtie2
RUN apt-get update && apt-get install -y curl unzip && rm -rf /var/lib/apt/lists/*
RUN curl -OL https://downloads.sourceforge.net/project/bowtie-bio/bowtie2/2.3.5.1/bowtie2-2.3.5.1-linux-x86_64.zip
RUN unzip bowtie2-2.3.5.1-linux-x86_64.zip

FROM debian:10-slim AS download-bowtie
RUN apt-get update && apt-get install -y curl unzip && rm -rf /var/lib/apt/lists/*
RUN curl -OL https://downloads.sourceforge.net/project/bowtie-bio/bowtie/1.2.3/bowtie-1.2.3-linux-x86_64.zip
RUN unzip bowtie-1.2.3-linux-x86_64.zip

FROM debian:10-slim AS download-star
RUN apt-get update && apt-get install -y curl
WORKDIR /download
RUN curl -OL https://github.com/alexdobin/STAR/archive/2.7.3a.tar.gz
RUN tar xzf 2.7.3a.tar.gz

FROM debian:10-slim AS download-hisat2
RUN apt-get update && apt-get install -y curl unzip
WORKDIR /download
RUN curl -o hisat2-220-Linux_x86_64.zip -L https://cloud.biohpc.swmed.edu/index.php/s/hisat2-220-Linux_x86_64/download
RUN unzip hisat2-220-Linux_x86_64.zip

FROM debian:10-slim AS download-rsem
RUN apt-get update && apt-get install -y curl unzip
WORKDIR /download
RUN curl -OL https://github.com/deweylab/RSEM/archive/v1.3.3.tar.gz
RUN tar xzf v1.3.3.tar.gz

FROM debian:10-slim
RUN apt-get update && \
    apt-get install -y ncurses-base zlib1g liblzma5 libbz2-1.0 curl libcurl4 r-base gcc g++ zlib1g-dev python perl-doc less && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
COPY --from=samtools-build /usr/local /usr/local
COPY --from=download-star /download/STAR-2.7.3a /opt/STAR-2.7.3a
COPY --from=download-bowtie2 /bowtie2-2.3.5.1-linux-x86_64 /opt/bowtie2
COPY --from=download-bowtie /bowtie-1.2.3-linux-x86_64 /opt/bowtie
COPY --from=download-hisat2 /download/hisat2-2.2.0 /opt/hisat2-2.2.0
COPY --from=download-rsem /download/RSEM-1.3.3 /build/RSEM-1.3.3
WORKDIR /build/RSEM-1.3.3
RUN make && make install && make install && make clean
ENV PATH=/opt/hisat2-2.2.0:/opt/bowtie2:/opt/bowtie:/opt/STAR-2.7.3a/bin/Linux_x86_64_static:${PATH}
ADD run.sh /
ENTRYPOINT [ "/bin/bash", "/run.sh" ]
