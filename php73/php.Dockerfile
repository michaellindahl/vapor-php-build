FROM vapor/runtime/compiler:latest as php_builder

SHELL ["/bin/bash", "-c"]

ENV BUILD_DIR="/tmp/build"
ENV INSTALL_DIR="/opt/vapor"

# Configure Default Compiler Variables

ENV PKG_CONFIG_PATH="${INSTALL_DIR}/lib64/pkgconfig:${INSTALL_DIR}/lib/pkgconfig" \
    PKG_CONFIG="/usr/bin/pkg-config" \
    PATH="${INSTALL_DIR}/bin:${PATH}"

ENV LD_LIBRARY_PATH="${INSTALL_DIR}/lib64:${INSTALL_DIR}/lib"

# Create All The Necessary Build Directories

RUN mkdir -p ${BUILD_DIR}  \
    ${INSTALL_DIR}/bin \
    ${INSTALL_DIR}/doc \
    ${INSTALL_DIR}/etc/php \
    ${INSTALL_DIR}/etc/php/conf.d \
    ${INSTALL_DIR}/include \
    ${INSTALL_DIR}/lib \
    ${INSTALL_DIR}/lib64 \
    ${INSTALL_DIR}/libexec \
    ${INSTALL_DIR}/sbin \
    ${INSTALL_DIR}/share

# Download and Build C library of Uber H3 

ENV H3_BUILD_DIR=${BUILD_DIR}/h3

RUN set -xe; \
    git clone https://github.com/uber/h3.git ${H3_BUILD_DIR}

WORKDIR ${H3_BUILD_DIR}/

RUN set -xe; \
    cmake -DBUILD_SHARED_LIBS=ON -DENABLE_DOCS=OFF -DENABLE_COVERAGE=OFF \
    -DBUILD_BENCHMARKS=OFF -DBUILD_FILTERS=ON -DBUILD_GENERATORS=OFF -DBUILD_TESTING=OFF . \
    && make -j4

RUN set -xe; \
    make install

# Move compiled bin execs to install directory

RUN cp ${H3_BUILD_DIR}/bin/* ${INSTALL_DIR}/bin
RUN cp ${H3_BUILD_DIR}/lib/libh3.* /opt/vapor/lib/;

# Verifed that Vapor deploys this via <?php exec('geoToH3 --resolution 10 --latitude 40.689167 --longitude -74.044444'); ?>

# Download and Build PHP Library of Uber H3

ENV H3_PHP_BUILD_DIR=${BUILD_DIR}/php-h3

RUN set -xe; \
    git clone https://github.com/neatlife/php-h3.git ${H3_PHP_BUILD_DIR}

RUN yum install -y php73-devel

WORKDIR ${H3_PHP_BUILD_DIR}/

RUN set -xe \
    && phpize \
    && ./configure \
    && make \
    && make install 

##### Output:

# + make
# /bin/sh /tmp/build/php-h3/libtool --mode=compile cc -DZEND_ENABLE_STATIC_TSRMLS_CACHE=1 -I. -I/tmp/build/php-h3 -DPHP_ATOM_INC -I/tmp/build/php-h3/include -I/tmp/build/php-h3/main -I/tmp/build/php-h3 -I/usr/include/php/7.3/php -I/usr/include/php/7.3/php/main -I/usr/include/php/7.3/php/TSRM -I/usr/include/php/7.3/php/Zend -I/usr/include/php/7.3/php/ext -I/usr/include/php/7.3/php/ext/date/lib  -DHAVE_CONFIG_H  -g -O2 -lh3 -std=c99  -c /tmp/build/php-h3/distance.c -o distance.lo 
# libtool: compile:  cc -DZEND_ENABLE_STATIC_TSRMLS_CACHE=1 -I. -I/tmp/build/php-h3 -DPHP_ATOM_INC -I/tmp/build/php-h3/include -I/tmp/build/php-h3/main -I/tmp/build/php-h3 -I/usr/include/php/7.3/php -I/usr/include/php/7.3/php/main -I/usr/include/php/7.3/php/TSRM -I/usr/include/php/7.3/php/Zend -I/usr/include/php/7.3/php/ext -I/usr/include/php/7.3/php/ext/date/lib -DHAVE_CONFIG_H -g -O2 -lh3 -std=c99 -c /tmp/build/php-h3/distance.c  -fPIC -DPIC -o .libs/distance.o
# /bin/sh /tmp/build/php-h3/libtool --mode=compile cc -DZEND_ENABLE_STATIC_TSRMLS_CACHE=1 -I. -I/tmp/build/php-h3 -DPHP_ATOM_INC -I/tmp/build/php-h3/include -I/tmp/build/php-h3/main -I/tmp/build/php-h3 -I/usr/include/php/7.3/php -I/usr/include/php/7.3/php/main -I/usr/include/php/7.3/php/TSRM -I/usr/include/php/7.3/php/Zend -I/usr/include/php/7.3/php/ext -I/usr/include/php/7.3/php/ext/date/lib  -DHAVE_CONFIG_H  -g -O2 -lh3 -std=c99  -c /tmp/build/php-h3/h3.c -o h3.lo 
# libtool: compile:  cc -DZEND_ENABLE_STATIC_TSRMLS_CACHE=1 -I. -I/tmp/build/php-h3 -DPHP_ATOM_INC -I/tmp/build/php-h3/include -I/tmp/build/php-h3/main -I/tmp/build/php-h3 -I/usr/include/php/7.3/php -I/usr/include/php/7.3/php/main -I/usr/include/php/7.3/php/TSRM -I/usr/include/php/7.3/php/Zend -I/usr/include/php/7.3/php/ext -I/usr/include/php/7.3/php/ext/date/lib -DHAVE_CONFIG_H -g -O2 -lh3 -std=c99 -c /tmp/build/php-h3/h3.c  -fPIC -DPIC -o .libs/h3.o
###### Lots of warnings. See https://github.com/neatlife/php-h3/issues/4
# /bin/sh /tmp/build/php-h3/libtool --mode=link cc -DPHP_ATOM_INC -I/tmp/build/php-h3/include -I/tmp/build/php-h3/main -I/tmp/build/php-h3 -I/usr/include/php/7.3/php -I/usr/include/php/7.3/php/main -I/usr/include/php/7.3/php/TSRM -I/usr/include/php/7.3/php/Zend -I/usr/include/php/7.3/php/ext -I/usr/include/php/7.3/php/ext/date/lib  -DHAVE_CONFIG_H  -g -O2 -lh3 -std=c99   -o h3.la -export-dynamic -avoid-version -prefer-pic -module -rpath /tmp/build/php-h3/modules  distance.lo h3.lo 
# libtool: link: cc -shared  -fPIC -DPIC  .libs/distance.o .libs/h3.o   -lh3  -O2   -Wl,-soname -Wl,h3.so -o .libs/h3.so
# libtool: link: ( cd ".libs" && rm -f "h3.la" && ln -s "../h3.la" "h3.la" )
# /bin/sh /tmp/build/php-h3/libtool --mode=install cp ./h3.la /tmp/build/php-h3/modules
# libtool: install: cp ./.libs/h3.so /tmp/build/php-h3/modules/h3.so
# libtool: install: cp ./.libs/h3.lai /tmp/build/php-h3/modules/h3.la
# libtool: finish: PATH="/opt/vapor/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/sbin" ldconfig -n /tmp/build/php-h3/modules
# ----------------------------------------------------------------------
# Libraries have been installed in:
#    /tmp/build/php-h3/modules
#
# If you ever happen to want to link against installed libraries
# in a given directory, LIBDIR, you must either use libtool, and
# specify the full pathname of the library, or use the `-LLIBDIR'
# flag during linking and do at least one of the following:
#    - add LIBDIR to the `LD_LIBRARY_PATH' environment variable
#      during execution
#    - add LIBDIR to the `LD_RUN_PATH' environment variable
#      during linking
#    - use the `-Wl,-rpath -Wl,LIBDIR' linker flag
#    - have your system administrator add LIBDIR to `/etc/ld.so.conf'
#
# See any operating system documentation about shared libraries for
# more information, such as the ld(1) and ld.so(8) manual pages.
# ----------------------------------------------------------------------
#
# Build complete.
# Don't forget to run 'make test'.
#
# + make install
# Installing shared extensions:     /usr/lib64/php/7.3/modules/

# This moves h3.so
RUN cp ${H3_PHP_BUILD_DIR}/modules/* ${INSTALL_DIR}/bin

#####  Debugging h3 build files:

# RUN ls -la ${H3_PHP_BUILD_DIR}  ===>  h3.c h3.la h3.lo h3.php php_h3.h
# RUN ls -la ${H3_PHP_BUILD_DIR}/modules  ===>  h3.so

##### For reference This is the install output of Pear:

# + make install PEAR_INSTALLER_URL=https://github.com/pear/pearweb_phars/raw/master/install-pear-nozlib.phar
# Installing shared extensions:     /opt/vapor/lib/php/extensions/no-debug-zts-20190902/
# Installing PHP CLI binary:        /opt/vapor/bin/
# Installing PHP CLI man page:      /opt/vapor/php/man/man1/
# Installing PHP FPM binary:        /opt/vapor/sbin/
# Installing PHP FPM defconfig:     /opt/vapor/etc/
# Installing PHP FPM man page:      /opt/vapor/php/man/man8/
# Installing PHP FPM status page:   /opt/vapor/php/php/fpm/
# Installing build environment:     /opt/vapor/lib/php/build/
# Installing header files:          /opt/vapor/include/php/
# Installing helper programs:       /opt/vapor/bin/
#   program: phpize
#   program: php-config
# Installing man pages:             /opt/vapor/php/man/man1/
#   page: phpize.1
#   page: php-config.1
# Installing PEAR environment:      /opt/vapor/lib/php/

# Build ZLIB (https://github.com/madler/zlib/releases)

ARG zlib
ENV VERSION_ZLIB=${zlib}
ENV ZLIB_BUILD_DIR=${BUILD_DIR}/zlib

RUN set -xe; \
    mkdir -p ${ZLIB_BUILD_DIR}; \
    curl -Ls  http://zlib.net/zlib-${VERSION_ZLIB}.tar.xz \
    | tar xJC ${ZLIB_BUILD_DIR} --strip-components=1

WORKDIR  ${ZLIB_BUILD_DIR}/

RUN set -xe; \
    make distclean \
    && CFLAGS="" \
    CPPFLAGS="-I${INSTALL_DIR}/include  -I/usr/include" \
    LDFLAGS="-L${INSTALL_DIR}/lib64 -L${INSTALL_DIR}/lib" \
    ./configure \
        --prefix=${INSTALL_DIR} \
        --64

RUN set -xe; \
    make install \
    && rm ${INSTALL_DIR}/lib/libz.a

# Build OpenSSL (https://github.com/openssl/openssl/releases)

ARG openssl
ENV VERSION_OPENSSL=${openssl}
ENV OPENSSL_BUILD_DIR=${BUILD_DIR}/openssl
ENV CA_BUNDLE_SOURCE="https://curl.haxx.se/ca/cacert.pem"
ENV CA_BUNDLE="${INSTALL_DIR}/ssl/cert.pem"

RUN set -xe; \
    mkdir -p ${OPENSSL_BUILD_DIR}; \
    curl -Ls  https://github.com/openssl/openssl/archive/OpenSSL_${VERSION_OPENSSL//./_}.tar.gz \
    | tar xzC ${OPENSSL_BUILD_DIR} --strip-components=1

WORKDIR  ${OPENSSL_BUILD_DIR}/

RUN set -xe; \
    CFLAGS="" \
    CPPFLAGS="-I${INSTALL_DIR}/include  -I/usr/include" \
    LDFLAGS="-L${INSTALL_DIR}/lib64 -L${INSTALL_DIR}/lib" \
    ./config \
        --prefix=${INSTALL_DIR} \
        --openssldir=${INSTALL_DIR}/ssl \
        --release \
        no-tests \
        shared \
        zlib

RUN set -xe; \
    make install \
    && curl -k -o ${CA_BUNDLE} ${CA_BUNDLE_SOURCE}

# Build LibSSH2 (https://github.com/libssh2/libssh2/releases/)

ARG libssh2
ENV VERSION_LIBSSH2=${libssh2}
ENV LIBSSH2_BUILD_DIR=${BUILD_DIR}/libssh2

RUN set -xe; \
    mkdir -p ${LIBSSH2_BUILD_DIR}/bin; \
    curl -Ls https://github.com/libssh2/libssh2/releases/download/libssh2-${VERSION_LIBSSH2}/libssh2-${VERSION_LIBSSH2}.tar.gz \
    | tar xzC ${LIBSSH2_BUILD_DIR} --strip-components=1

WORKDIR  ${LIBSSH2_BUILD_DIR}/bin/

RUN set -xe; \
    CFLAGS="" \
    CPPFLAGS="-I${INSTALL_DIR}/include  -I/usr/include" \
    LDFLAGS="-L${INSTALL_DIR}/lib64 -L${INSTALL_DIR}/lib" \
    cmake .. \
        -DBUILD_SHARED_LIBS=ON \
        -DCRYPTO_BACKEND=OpenSSL \
        -DENABLE_ZLIB_COMPRESSION=ON \
        -DCMAKE_INSTALL_PREFIX=${INSTALL_DIR} \
        -DCMAKE_BUILD_TYPE=RELEASE

RUN set -xe; \
    cmake  --build . --target install

# Build nghttp2 (https://github.com/nghttp2/nghttp2/releases/)

ARG nghttp2
ENV VERSION_NGHTTP2=${nghttp2}
ENV NGHTTP2_BUILD_DIR=${BUILD_DIR}/nghttp2

RUN set -xe; \
    mkdir -p ${NGHTTP2_BUILD_DIR}/bin; \
    curl -Ls https://github.com/nghttp2/nghttp2/releases/download/v${VERSION_NGHTTP2}/nghttp2-${VERSION_NGHTTP2}.tar.gz \
    | tar xzC ${NGHTTP2_BUILD_DIR} --strip-components=1

WORKDIR  ${NGHTTP2_BUILD_DIR}/

RUN set -xe; \
    autoreconf -i && \
    automake && \
    autoconf && \
    ./configure && \
    make && \
    make install

# Build Curl (https://github.com/curl/curl/releases/)

ARG curl
ENV VERSION_CURL=${curl}
ENV CURL_BUILD_DIR=${BUILD_DIR}/curl

RUN set -xe; \
    mkdir -p ${CURL_BUILD_DIR}/bin; \
    curl -Ls https://github.com/curl/curl/archive/curl-${VERSION_CURL//./_}.tar.gz \
    | tar xzC ${CURL_BUILD_DIR} --strip-components=1

WORKDIR  ${CURL_BUILD_DIR}/

RUN set -xe; \
    ./buildconf \
     && CFLAGS="" \
        CPPFLAGS="-I${INSTALL_DIR}/include  -I/usr/include" \
        LDFLAGS="-L${INSTALL_DIR}/lib64 -L${INSTALL_DIR}/lib" \
        ./configure \
            --prefix=${INSTALL_DIR} \
            --with-ca-bundle=${CA_BUNDLE} \
            --enable-shared \
            --disable-static \
            --enable-optimize \
            --disable-warnings \
            --disable-dependency-tracking \
            --with-zlib \
            --enable-http \
            --enable-ftp  \
            --enable-file \
            --enable-ldap \
            --enable-ldaps  \
            --enable-proxy  \
            --enable-tftp \
            --enable-ipv6 \
            --enable-openssl-auto-load-config \
            --enable-cookies \
            --with-gnu-ld \
            --with-ssl \
            --with-libssh2 \
            --with-nghttp2=/usr/local

RUN set -xe; \
    make install

# Build LibXML2 (https://github.com/GNOME/libxml2/releases)

ARG libxml2
ENV VERSION_XML2=${libxml2}
ENV XML2_BUILD_DIR=${BUILD_DIR}/xml2

RUN set -xe; \
    mkdir -p ${XML2_BUILD_DIR}; \
    curl -Ls http://xmlsoft.org/sources/libxml2-${VERSION_XML2}.tar.gz \
    | tar xzC ${XML2_BUILD_DIR} --strip-components=1

WORKDIR  ${XML2_BUILD_DIR}/

RUN set -xe; \
    CFLAGS="" \
    CPPFLAGS="-I${INSTALL_DIR}/include  -I/usr/include" \
    LDFLAGS="-L${INSTALL_DIR}/lib64 -L${INSTALL_DIR}/lib" \
    ./configure \
        --prefix=${INSTALL_DIR} \
        --with-sysroot=${INSTALL_DIR} \
        --enable-shared \
        --disable-static \
        --with-html \
        --with-history \
        --enable-ipv6=no \
        --with-icu \
        --with-zlib=${INSTALL_DIR} \
        --without-python

RUN set -xe; \
    make install \
    && cp xml2-config ${INSTALL_DIR}/bin/xml2-config

# Build Libzip (https://github.com/nih-at/libzip/releases)

ARG libzip
ENV VERSION_ZIP=${libzip}
ENV ZIP_BUILD_DIR=${BUILD_DIR}/zip

RUN set -xe; \
    mkdir -p ${ZIP_BUILD_DIR}/bin/; \
# Download and upack the source code
    curl -Ls https://github.com/nih-at/libzip/archive/rel-${VERSION_ZIP//./-}.tar.gz \
  | tar xzC ${ZIP_BUILD_DIR} --strip-components=1

# Move into the unpackaged code directory
WORKDIR  ${ZIP_BUILD_DIR}/bin/

# Configure the build
RUN set -xe; \
    CFLAGS="" \
    CPPFLAGS="-I${INSTALL_DIR}/include  -I/usr/include" \
    LDFLAGS="-L${INSTALL_DIR}/lib64 -L${INSTALL_DIR}/lib" \
    cmake .. \
    -DCMAKE_INSTALL_PREFIX=${INSTALL_DIR} \
    -DCMAKE_BUILD_TYPE=RELEASE

RUN set -xe; \
    cmake  --build . --target install

# Build Libsodium (https://github.com/jedisct1/libsodium/releases)

ARG libsodium
ENV VERSION_LIBSODIUM=${libsodium}
ENV LIBSODIUM_BUILD_DIR=${BUILD_DIR}/libsodium

RUN set -xe; \
    mkdir -p ${LIBSODIUM_BUILD_DIR}; \
    curl -Ls https://github.com/jedisct1/libsodium/archive/${VERSION_LIBSODIUM}.tar.gz \
    | tar xzC ${LIBSODIUM_BUILD_DIR} --strip-components=1

WORKDIR  ${LIBSODIUM_BUILD_DIR}/

RUN set -xe; \
    CFLAGS="" \
    CPPFLAGS="-I${INSTALL_DIR}/include  -I/usr/include" \
    LDFLAGS="-L${INSTALL_DIR}/lib64 -L${INSTALL_DIR}/lib" \
    ./autogen.sh \
    && ./configure --prefix=${INSTALL_DIR}

RUN set -xe; \
    make install

# Build Postgres (https://github.com/postgres/postgres/releases/)

ARG postgres
ENV VERSION_POSTGRES=${postgres}
ENV POSTGRES_BUILD_DIR=${BUILD_DIR}/postgres

RUN set -xe; \
    mkdir -p ${POSTGRES_BUILD_DIR}/bin; \
    curl -Ls https://github.com/postgres/postgres/archive/REL${VERSION_POSTGRES//./_}.tar.gz \
    | tar xzC ${POSTGRES_BUILD_DIR} --strip-components=1

WORKDIR  ${POSTGRES_BUILD_DIR}/

RUN set -xe; \
    CFLAGS="" \
    CPPFLAGS="-I${INSTALL_DIR}/include  -I/usr/include" \
    LDFLAGS="-L${INSTALL_DIR}/lib64 -L${INSTALL_DIR}/lib" \
    ./configure --prefix=${INSTALL_DIR} --with-openssl --without-readline

RUN set -xe; cd ${POSTGRES_BUILD_DIR}/src/interfaces/libpq && make && make install
RUN set -xe; cd ${POSTGRES_BUILD_DIR}/src/bin/pg_config && make && make install
RUN set -xe; cd ${POSTGRES_BUILD_DIR}/src/backend && make generated-headers
RUN set -xe; cd ${POSTGRES_BUILD_DIR}/src/include && make install

# Build libjpeg

ARG libjpeg
ENV VERSION_LIBJPEG=${libjpeg}
ENV LIBJPEG_BUILD_DIR=${BUILD_DIR}/libjpeg

RUN set -xe; \
    mkdir -p ${LIBJPEG_BUILD_DIR}/bin; \
    curl -Ls http://www.ijg.org/files/jpegsrc.${VERSION_LIBJPEG}.tar.gz \
    | tar xzC ${LIBJPEG_BUILD_DIR} --strip-components=1

WORKDIR  ${LIBJPEG_BUILD_DIR}/

RUN set -xe; \
    CFLAGS="" \
    CPPFLAGS="-I${INSTALL_DIR}/include  -I/usr/include" \
    LDFLAGS="-L${INSTALL_DIR}/lib64 -L${INSTALL_DIR}/lib" \
    ./configure \
        --prefix=${INSTALL_DIR} \
        --enable-shared \
        --disable-static

RUN set -xe; \
    make install

# Build libpng

ARG libpng
ENV VERSION_LIBPNG=${libpng}
ENV LIBPNG_BUILD_DIR=${BUILD_DIR}/libpng

RUN set -xe; \
    mkdir -p ${LIBPNG_BUILD_DIR}/bin; \
    curl -Ls https://download.sourceforge.net/libpng/libpng-${VERSION_LIBPNG}.tar.gz \
    | tar xzC ${LIBPNG_BUILD_DIR} --strip-components=1

WORKDIR  ${LIBPNG_BUILD_DIR}/

RUN set -xe; \
    CFLAGS="" \
    CPPFLAGS="-I${INSTALL_DIR}/include  -I/usr/include" \
    LDFLAGS="-L${INSTALL_DIR}/lib64 -L${INSTALL_DIR}/lib" \
    ./configure \
        --prefix=${INSTALL_DIR} \
        --enable-shared \
        --disable-static

RUN set -xe; \
    make install

# Build PHP

ARG php
ENV VERSION_PHP=${php}
ENV PHP_BUILD_DIR=${BUILD_DIR}/php

RUN set -xe; \
    mkdir -p ${PHP_BUILD_DIR}; \
    curl -Ls https://github.com/php/php-src/archive/php-${VERSION_PHP}.tar.gz \
    | tar xzC ${PHP_BUILD_DIR} --strip-components=1

# Configure The PHP Build

WORKDIR  ${PHP_BUILD_DIR}/

RUN LD_LIBRARY_PATH= yum install -y readline-devel gettext-devel libicu-devel libxslt-devel ImageMagick-devel

RUN set -xe \
 && ./buildconf --force \
 && CFLAGS="-fstack-protector-strong -fpic -fpie -Os -I${INSTALL_DIR}/include -I/usr/include -ffunction-sections -fdata-sections" \
    CPPFLAGS="-fstack-protector-strong -fpic -fpie -Os -I${INSTALL_DIR}/include -I/usr/include -ffunction-sections -fdata-sections" \
    LDFLAGS="-L${INSTALL_DIR}/lib64 -L${INSTALL_DIR}/lib -Wl,-O1 -Wl,--strip-all -Wl,--hash-style=both -pie" \
    ./configure \
        --build=x86_64-pc-linux-gnu \
        --prefix=${INSTALL_DIR} \
        --enable-option-checking=fatal \
        --enable-maintainer-zts \
        --with-config-file-path=${INSTALL_DIR}/etc/php \
        --with-config-file-scan-dir=${INSTALL_DIR}/etc/php/conf.d:/var/task/php/conf.d \
        --enable-fpm \
        --disable-cgi \
        --enable-cli \
        --with-png-dir=${INSTALL_DIR} \
        --with-jpeg-dir=${INSTALL_DIR} \
        --with-xsl=${INSTALL_DIR} \
        --with-gd \
        --disable-phpdbg \
        --disable-phpdbg-webhelper \
        --with-sodium \
        --with-readline \
        --with-openssl \
        --with-zlib=${INSTALL_DIR} \
        --with-zlib-dir=${INSTALL_DIR} \
        --with-curl=${INSTALL_DIR} \
        --enable-bcmath \
        --enable-sockets \
        --enable-exif \
        --enable-ftp \
        --with-gettext \
        --enable-mbstring \
        --enable-soap \
        --with-pdo-mysql=shared,mysqlnd \
        --enable-pcntl \
        --enable-zip \
        --with-pdo-pgsql=shared,${INSTALL_DIR} \
        --enable-intl=shared \
        --enable-opcache-file
# configure: error: unrecognized options: --enable-h3
#        --enable-h3

RUN make -j $(nproc)

# Override PEAR URL Since It Is Down

RUN set -xe; \
    make install PEAR_INSTALLER_URL='https://github.com/pear/pearweb_phars/raw/master/install-pear-nozlib.phar'; \
    { find ${INSTALL_DIR}/bin ${INSTALL_DIR}/sbin -type f -perm +0111 -exec strip --strip-all '{}' + || true; }; \
    make clean; \
    cp php.ini-production ${INSTALL_DIR}/etc/php/php.ini

# RUN pecl install redis
RUN pecl install -f redis

# RUN pecl install imagick
RUN pecl install imagick

# Strip All Unneeded Symbols

RUN find ${INSTALL_DIR} -type f -name "*.so*" -o -name "*.a"  -exec strip --strip-unneeded {} \;
RUN find ${INSTALL_DIR} -type f -executable -exec sh -c "file -i '{}' | grep -q 'x-executable; charset=binary'" \; -print|xargs strip --strip-all

# Symlink All Binaries / Libaries

RUN mkdir -p /opt/bin
RUN mkdir -p /opt/lib
RUN mkdir -p /opt/lib/curl

RUN cp /opt/vapor/bin/* /opt/bin
RUN cp /opt/vapor/sbin/* /opt/bin
RUN cp /opt/vapor/lib/php/extensions/no-debug-zts-20180731/* /opt/bin

RUN cp /opt/vapor/lib/* /opt/lib || true
RUN cp /opt/vapor/lib/libcurl* /opt/lib/curl || true

RUN cp "${INSTALL_DIR}/ssl/cert.pem" /opt/lib/curl/cert.pem
RUN cp /opt/vapor/lib64/* /opt/lib || true

RUN ls /opt/bin
RUN /opt/bin/php -i | grep curl


FROM amazonlinux:latest as awsclibuilder

WORKDIR /root

RUN curl "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip" -o "awscli-bundle.zip"

RUN yum update -y && yum install -y unzip

RUN unzip awscli-bundle.zip && cd awscli-bundle;

RUN ./awscli-bundle/install -i /opt/awscli -b /opt/awscli/aws


# Copy Everything To The Base Container

FROM amazonlinux:2018.03

ENV INSTALL_DIR="/opt/vapor"

ENV PATH="/opt/bin:${PATH}" \
    LD_LIBRARY_PATH="${INSTALL_DIR}/lib64:${INSTALL_DIR}/lib"

RUN mkdir -p /opt

WORKDIR /opt

COPY --from=php_builder /opt /opt
COPY --from=awsclibuilder /opt/awscli/lib/python2.7/site-packages/ /opt/awscli/
COPY --from=awsclibuilder /opt/awscli/bin/ /opt/awscli/bin/
COPY --from=awsclibuilder /opt/awscli/bin/aws /opt/awscli/aws

RUN LD_LIBRARY_PATH= yum -y install zip

RUN rm -rf /opt/awscli/pip* /opt/awscli/setuptools* /opt/awscli/awscli/examples
