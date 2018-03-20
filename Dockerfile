FROM node:9-alpine AS build
LABEL maintainer="arne@hilmann.de"

USER root

RUN apk update && apk add curl python cairo-dev pkgconf pixman-dev pango-dev g++ make git php5 && rm -rf /var/cache/apk/*

RUN npm -g config set user root
RUN npm install -g canvas --build-from-source
RUN npm install -g underscore xpath xmldom express body-parser deasync

WORKDIR /
RUN git clone https://github.com/dhobsd/asciitosvg.git
RUN curl -OL https://cdn.rawgit.com/pshihn/rough/9be60b1e/dist/rough.min.js
RUN curl -OL https://cdn.rawgit.com/pshihn/rough/9be60b1e/dist/rough.js
RUN curl -OL https://github.com/ipython/xkcd-font/raw/master/xkcd-script/font/xkcd-script.ttf


FROM node:9-alpine
LABEL maintainer="arne@hilmann.de"

COPY --from=build /asciitosvg /asciitosvg/
RUN ln -sf /asciitosvg/a2s /usr/bin/a2s
COPY --from=build /usr/bin/php5 /usr/bin/php

COPY --from=build /usr/bin/fc-* /usr/bin/

# ( ldd /usr/bin/fc-cache; ldd /usr/lib/libcairo.*; ldd /usr/lib/libpangocairo-*; ldd /usr/bin/php ) |  sed -n "s/.* => /    /;T;s/ .*//;s/\.so\..*/.* \\\/;p"  | sort | uniq

COPY --from=build \
    /lib/ld-musl-x86_64.* \
    /lib/libcrypto.* \
    /lib/libz.* \
    /lib/
COPY --from=build \
    /usr/lib/libX11.* \
    /usr/lib/libXau.* \
    /usr/lib/libXdmcp.* \
    /usr/lib/libXext.* \
    /usr/lib/libXrender.* \
    /usr/lib/libbsd.* \
    /usr/lib/libbz2.* \
    /usr/lib/libcairo.* \
    /usr/lib/libexpat.* \
    /usr/lib/libffi.* \
    /usr/lib/libfontconfig.* \
    /usr/lib/libfreetype.* \
    /usr/lib/libglib-2.0.* \
    /usr/lib/libgobject-2.0.* \
    /usr/lib/libgraphite2.* \
    /usr/lib/libharfbuzz.* \
    /usr/lib/libintl.* \
    /usr/lib/libncursesw.* \
    /usr/lib/libpango-1.0.* \
    /usr/lib/libpangoft2-1.0.* \
    /usr/lib/libpcre.* \
    /usr/lib/libpixman-1.* \
    /usr/lib/libpng16.* \
    /usr/lib/libreadline.* \
    /usr/lib/libxcb-render.* \
    /usr/lib/libxcb-shm.* \
    /usr/lib/libxcb.* \
    /usr/lib/libxml2.* \
    /usr/lib/libpangocairo-* \
    /usr/lib/


RUN /sbin/ldconfig || :

# xkcd font
RUN mkdir -p /usr/share/fonts
COPY --from=build xkcd-script.ttf /usr/share/fonts/
COPY --from=build /etc/fonts /etc/fonts
ENV FONTCONFIG_PATH=/etc/fonts
RUN fc-cache -v -f
RUN fc-list

# node modules
COPY --from=build /usr/local/lib/node_modules /usr/local/lib/node_modules


# switch to non-root user
USER node
WORKDIR /home/node
RUN mkdir -p .a2s/objects

ENV NODE_PATH=/usr/local/lib/node_modules/
COPY a2sketch.webserver .
COPY --from=build /rough.* ./

ENTRYPOINT ["node", "a2sketch.webserver"]
