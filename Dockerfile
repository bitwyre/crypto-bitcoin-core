
# Stage 1 - Build

FROM ubuntu:18.04 as builder
WORKDIR /app/src

RUN apt-get update -y && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends apt-utils software-properties-common && \
    add-apt-repository ppa:bitcoin/bitcoin && \
    apt-get update -y && \
    apt-get install -y libtool autotools-dev libdb4.8-dev libdb4.8++-dev automake pkg-config \
    bsdmainutils libzmq3-dev libevent-dev libboost-system-dev libboost-filesystem-dev \
    libboost-chrono-dev libboost-test-dev libboost-thread-dev clang-8 clang-format-8 clang-tidy-8 \
    clang-tools-8 llvm-8 lld-8 lldb-8 python3 libssl-dev && \
    update-alternatives \
    --install /usr/lib/llvm              llvm             /usr/lib/llvm-8 10 \
    --slave   /usr/bin/llvm-config       llvm-config      /usr/bin/llvm-config-8  \
    --slave   /usr/bin/llvm-ar           llvm-ar          /usr/bin/llvm-ar-8 \
    --slave   /usr/bin/llvm-as           llvm-as          /usr/bin/llvm-as-8 \
    --slave   /usr/bin/llvm-bcanalyzer   llvm-bcanalyzer  /usr/bin/llvm-bcanalyzer-8 \
    --slave   /usr/bin/llvm-cov          llvm-cov         /usr/bin/llvm-cov-8 \
    --slave   /usr/bin/llvm-diff         llvm-diff        /usr/bin/llvm-diff-8 \
    --slave   /usr/bin/llvm-dis          llvm-dis         /usr/bin/llvm-dis-8 \
    --slave   /usr/bin/llvm-dwarfdump    llvm-dwarfdump   /usr/bin/llvm-dwarfdump-8 \
    --slave   /usr/bin/llvm-extract      llvm-extract     /usr/bin/llvm-extract-8 \
    --slave   /usr/bin/llvm-link         llvm-link        /usr/bin/llvm-link-8 \
    --slave   /usr/bin/llvm-mc           llvm-mc          /usr/bin/llvm-mc-8 \
    --slave   /usr/bin/llvm-nm           llvm-nm          /usr/bin/llvm-nm-8 \
    --slave   /usr/bin/llvm-objdump      llvm-objdump     /usr/bin/llvm-objdump-8 \
    --slave   /usr/bin/llvm-ranlib       llvm-ranlib      /usr/bin/llvm-ranlib-8 \
    --slave   /usr/bin/llvm-readobj      llvm-readobj     /usr/bin/llvm-readobj-8 \
    --slave   /usr/bin/llvm-rtdyld       llvm-rtdyld      /usr/bin/llvm-rtdyld-8 \
    --slave   /usr/bin/llvm-size         llvm-size        /usr/bin/llvm-size-8 \
    --slave   /usr/bin/llvm-stress       llvm-stress      /usr/bin/llvm-stress-8 \
    --slave   /usr/bin/llvm-symbolizer   llvm-symbolizer  /usr/bin/llvm-symbolizer-8 \
    --slave   /usr/bin/llvm-tblgen       llvm-tblgen      /usr/bin/llvm-tblgen-8 && \
    update-alternatives \
    --install /usr/bin/clang                    clang                       /usr/bin/clang-8 10 \
    --slave   /usr/bin/clang++                  clang++                     /usr/bin/clang++-8 \
    --slave   /usr/bin/lld                      lld                         /usr/bin/lld-8 \
    --slave   /usr/bin/clang-format             clang-format                /usr/bin/clang-format-8 \
    --slave   /usr/bin/clang-tidy               clang-tidy                  /usr/bin/clang-tidy-8 \
    --slave   /usr/bin/clang-tidy-diff.py       clang-tidy-diff.py          /usr/bin/clang-tidy-diff-8.py \
    --slave   /usr/bin/clang-include-fixer      clang-include-fixer         /usr/bin/clang-include-fixer-8 \
    --slave   /usr/bin/clang-offload-bundler    clang-offload-bundler       /usr/bin/clang-offload-bundler-8 \
    --slave   /usr/bin/clangd                   clangd                      /usr/bin/clangd-8 \
    --slave   /usr/bin/clang-check              clang-check                 /usr/bin/clang-check-8 \
    --slave   /usr/bin/scan-view                scan-view                   /usr/bin/scan-view-8 \
    --slave   /usr/bin/clang-apply-replacements clang-apply-replacements    /usr/bin/clang-apply-replacements-8 \
    --slave   /usr/bin/clang-query              clang-query                 /usr/bin/clang-query-8 \
    --slave   /usr/bin/modularize               modularize                  /usr/bin/modularize-8 \
    --slave   /usr/bin/sancov                   sancov                      /usr/bin/sancov-8 \
    --slave   /usr/bin/c-index-test             c-index-test                /usr/bin/c-index-test-8 \
    --slave   /usr/bin/clang-reorder-fields     clang-reorder-fields        /usr/bin/clang-reorder-fields-8 \
    --slave   /usr/bin/clang-change-namespace   clang-change-namespace      /usr/bin/clang-change-namespace-8 \
    --slave   /usr/bin/clang-import-test        clang-import-test           /usr/bin/clang-import-test-8 \
    --slave   /usr/bin/scan-build               scan-build                  /usr/bin/scan-build-8 \
    --slave   /usr/bin/scan-build-py            scan-build-py               /usr/bin/scan-build-py-8 \
    --slave   /usr/bin/clang-cl                 clang-cl                    /usr/bin/clang-cl-8 \
    --slave   /usr/bin/clang-rename             clang-rename                /usr/bin/clang-rename-8 \
    --slave   /usr/bin/find-all-symbols         find-all-symbols            /usr/bin/find-all-symbols-8 \
    --slave   /usr/bin/lldb                     lldb                        /usr/bin/lldb-8 \
    --slave   /usr/bin/lldb-server              lldb-server                 /usr/bin/lldb-server-8

COPY bitcoin ./bitcoin
WORKDIR /app/src/bitcoin

RUN ./autogen.sh && \
    ./configure CXX=clang++ CC=clang CXXFLAGS="-O3" CFLAGS="-O3" --enable-hardening --with-zmq && \
    make -j8


# Stage 2 - Production Image

FROM ubuntu:18.04
LABEL maintainer.0="Dendi Suhubdy (dendi@bitwyre.com)" \
      maintainer.1="Yefta Sutanto (yefta@bitwyre.com)" \
      maintainer.2="Aditya Kresna (kresna@bitwyre.com)"

RUN useradd -r bitcoin && \
    apt-get update && \
    apt-get install -y --no-install-recommends gosu

ENV BITCOIN_DATA="/home/bitcoin/.bitcoin"

COPY --from=builder /app/src/bitcoin/src/bitcoind /usr/local/bin/
COPY --from=builder /app/src/bitcoin/src/bitcoin-cli /usr/local/bin/
COPY --from=builder /app/src/bitcoin/src/bitcoin-tx /usr/local/bin/
COPY --from=builder /app/src/bitcoin/src/bitcoin-wallet /usr/local/bin/
COPY docker-entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

VOLUME ["/home/bitcoin/.bitcoin"]

EXPOSE 8332 8333 18332 18333 18443 18444 28332

ENTRYPOINT ["/entrypoint.sh"]
CMD ["bitcoind"]
