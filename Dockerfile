
# Stage 1 - Build

FROM bitwyre/builder-btcd:u1804-gcc as builder

COPY bitcoin /app/src/bitcoin
WORKDIR /app/src/bitcoin/

ENV CXXFLAGS="-O3"
ENV CFLAGS="-O3"
ENV NO_QT=1

RUN echo "\nSubmodule files:"&& \
    ls -Falg --group-directories-first && \
    echo && \
    gcc --version && \
    cd depends && \
    mkdir x86_64-pc-linux-gnu && \
    make -j8
RUN ./autogen.sh && \
    ./configure LDFLAGS="-static-libstdc++" --prefix="/app/src/bitcoin/depends/x86_64-pc-linux-gnu" \
    --enable-glibc-back-compat --enable-hardening --with-zmq --disable-man \
    --disable-bench --disable-test --without-gui
RUN make install -j8
RUN cd /app/src/bitcoin/depends/x86_64-pc-linux-gnu && \
    ls -Falg --group-directories-first && \
    strip bin/bitcoind && \
    strip bin/bitcoin-cli && \
    strip bin/bitcoin-tx && \
    strip bin/bitcoin-wallet && \
    strip lib/libbitcoinconsensus.a && \
    strip lib/libbitcoinconsensus.so.0.0.0


# Stage 2 - Production Image

FROM ubuntu:18.04

LABEL maintainer.0="Dendi Suhubdy (dendi@bitwyre.com)" \
    maintainer.1="Yefta Sutanto (yefta@bitwyre.com)" \
    maintainer.2="Aditya Kresna (kresna@bitwyre.com)"

RUN apt-get update && \
    apt-get install -y --no-install-recommends gosu && \
    rm -rf /var/lib/apt/lists/* && \
    useradd -r bitcoin
RUN mkdir -p /home/bitcoin/.bitcoin && \
    chown -R bitcoin /home/bitcoin

COPY --from=builder /app/src/bitcoin/depends/x86_64-pc-linux-gnu /usr/local
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

VOLUME ["/home/bitcoin/.bitcoin"]
EXPOSE 8332 8333 18332 18333 18443 18444 28332 28333 28334 28335

ENV BITCOIN_DATA = "/home/bitcoin/.bitcoin"

ENTRYPOINT [ "/./docker-entrypoint.sh" ]
CMD ["bitcoind"]
