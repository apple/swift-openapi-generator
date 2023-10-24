ARG swift_version=5.8
ARG ubuntu_version=jammy
ARG base_image=swift:${swift_version}-${ubuntu_version}

FROM ${base_image}
ARG swift_version
ARG ubuntu_version

# set as UTF-8
RUN apt-get update && apt-get install -y locales locales-all
ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8

# tools
RUN mkdir -p $HOME/.tools
RUN echo 'export PATH="$HOME/.tools:$PATH"' >> $HOME/.profile

# swift-format
ARG swiftformat_version=509.0.0
RUN git clone --branch $swiftformat_version --depth 1 https://github.com/apple/swift-format $HOME/.tools/swift-format-source
RUN cd $HOME/.tools/swift-format-source && swift build -c release
RUN ln -s $HOME/.tools/swift-format-source/.build/release/swift-format $HOME/.tools/swift-format

# jq
RUN apt-get install -y jq
