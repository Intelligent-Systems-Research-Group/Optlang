FROM nvidia/cuda:9.2-devel
COPY --from=joms/clang:latest /clang/install /clang/install
COPY --from=joms/terra:latest /terra/install /terra/install
ADD . /Optlang/
WORKDIR /Optlang/API
RUN apt-get update && apt-get install -y cmake g++ \
&& export CC=/clang/install/bin/clang \
&& export CXX=/clang/install/bin/clang++ \
&& export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/clang/install/lib/ && \
echo "alias llvm-config='/clang/install/bin/llvm-config'" >> ~/.bashrc && \
echo "alias clang='/clang/install/bin/clang'" >> ~/.bashrc && \
echo "alias clang++='/clang/install/bin/clang++'" >> ~/.bashrc && make
