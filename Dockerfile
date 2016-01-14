FROM centos

MAINTAINER Kyoji Konishi<koniyan@gmail.com>

ENV PATH=$PATH:/opt/bin
RUN mkdir /etc/resolver

# dependencies
RUN yum update -y & \
    yum install -y autoconf automake cmake freetype-devel gcc gcc-c++ git libtool make mercurial nasm pkgconfig zlib-devel unzip && \
    yum clean all
RUN echo "nameserver 8.8.8.8" > /etc/resolver/github.com
RUN echo "nameserver 8.8.8.8" > /etc/resolver/git.videolan.org
RUN mkdir /opt/ffmpeg_sources

# Yasm
RUN cd /opt/ffmpeg_sources && \
    git clone --depth 1 git://github.com/yasm/yasm.git && \
    cd yasm && \
    autoreconf -fiv && \
    ./configure --prefix="/opt/ffmpeg_build" --bindir="/opt/bin" && \
    make && \
    make install && \
    make distclean

# libx264
RUN cd /opt/ffmpeg_sources && \
    git clone git://git.videolan.org/x264.git && \
    cd x264 && \
    ./configure --prefix="/opt/ffmpeg_build" --bindir="/opt/bin" --enable-static && \
    make && \
    make install && \
    make distclean

# libx265
RUN cd /opt/ffmpeg_sources && \
    hg clone https://bitbucket.org/multicoreware/x265 && \
    cd /opt/ffmpeg_sources/x265/build/linux && \
    cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX="/opt/ffmpeg_build" -DENABLE_SHARED:bool=off ../../source && \
    make && \
    make install

# libfdk_aac
RUN cd /opt/ffmpeg_sources && \
    git clone --depth 1 git://git.code.sf.net/p/opencore-amr/fdk-aac && \
    cd fdk-aac && \
    autoreconf -fiv && \
    ./configure --prefix="/opt/ffmpeg_build" --disable-shared && \
    make && \
    make install && \
    make distclean

# libmp3lame
RUN cd /opt/ffmpeg_sources && \
    curl -L -O http://downloads.sourceforge.net/project/lame/lame/3.99/lame-3.99.5.tar.gz && \
    tar xzvf lame-3.99.5.tar.gz && \
    cd lame-3.99.5 && \
    ./configure --prefix="/opt/ffmpeg_build" --bindir="/opt/bin" --disable-shared --enable-nasm && \
    make && \
    make install && \
    make distclean

# libvpx
RUN cd /opt/ffmpeg_sources && \
    git clone --depth 1 -b v1.4.0 https://chromium.googlesource.com/webm/libvpx.git && \
    cd libvpx && \
    ./configure --prefix="/opt/ffmpeg_build" --disable-examples && \
    make && \
    make install && \
    make clean

# libsodium
RUN cd /opt/ffmpeg_sources && \
    git clone --depth 1 https://github.com/jedisct1/libsodium && \
    cd libsodium && \
    ./autogen.sh && \
    PKG_CONFIG_PATH="/opt/ffmpeg_build/lib/pkgconfig" ./configure --prefix="/opt/ffmpeg_build" && \
    make && \
    make install && \
    make clean

# libzmq
RUN cd /opt/ffmpeg_sources && \
    git clone --depth 1 https://github.com/zeromq/libzmq && \
    cd libzmq && \
    ./autogen.sh && \
    PKG_CONFIG_PATH="/opt/ffmpeg_build/lib/pkgconfig" ./configure --prefix="/opt/ffmpeg_build" && \
    make && \
    make install && \
    make clean

# ffmpeg
ADD . /opt/ffmpeg_sources/ffmpeg
RUN cd /opt/ffmpeg_sources/ffmpeg && \
    PKG_CONFIG_PATH="/opt/ffmpeg_build/lib/pkgconfig" ./configure --prefix="/opt/ffmpeg_build" --extra-cflags="-I/opt/ffmpeg_build/include" --extra-ldflags="-L/opt/ffmpeg_build/lib" --bindir="/opt/bin" --pkg-config-flags="--static" --enable-gpl --enable-nonfree --enable-libfdk_aac --enable-libmp3lame --enable-libvpx --enable-libx264 --enable-libzmq --enable-decoder=png --enable-encoder=png --enable-libfreetype && \
    make && \
    make install && \
    make distclean && \
    hash -r

WORKDIR "/opt/bin"
env LD_LIBRARY_PATH=/opt/ffmpeg_build/lib
ENV TZ JST-9
CMD "/opt/bin/ffmpeg"

EXPOSE 1935
