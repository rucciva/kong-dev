FROM ubuntu:18.04
# docker images for debugging kong plugin
# based on http://lua-programming.blogspot.co.id/2015/12/how-to-debug-kong-plugins-on-windows.html and https://github.com/Kong/kong-vagrant

# global dependency
RUN apt-get update &&\
	apt-get install -y \
	git \
	curl \
	make \
	pkg-config \
	unzip \
	libpcre3-dev \
	apt-transport-https \
	language-pack-en \
	wget \
	netcat \
	openssl \
	libpcre3 \
	dnsmasq \
	procps \
	perl \
	iptables \
	libcap2-bin \
	nmap \
	libssl-dev \
	m4 \
	cpanminus \
	rsync

# install zerobrane
ARG ZEROBRANE_VERSION 
ENV ZEROBRANE_VERSION ${ZEROBRANE_VERSION:-1.90}
RUN apt-get install -y sudo &&\
	mkdir -p /tmp/zerobrane/ &&\
	curl https://download.zerobrane.com/ZeroBraneStudioEduPack-${ZEROBRANE_VERSION}-linux.sh -o /tmp/zerobrane/zerobrane.sh &&\
	chmod +x /tmp/zerobrane/zerobrane.sh &&\
	/tmp/zerobrane/zerobrane.sh

# install kong and prepare development environment
ARG KONG_VERSION
ENV KONG_VERSION ${KONG_VERSION:-2.0.0}
ENV KONG_SRC_PATH /usr/local/src/kong 
RUN echo "Fetching and installing Kong..." &&\
	set +o errexit &&\
	wget -q -O kong.deb https://bintray.com/kong/kong-deb/download_file?file_path=kong-${KONG_VERSION}.bionic.amd64.deb &&\
	set -o errexit &&\
	dpkg -i kong.deb &&\
	rm kong.deb &&\
	git clone https://github.com/Kong/kong $KONG_SRC_PATH &&\
	cd $KONG_SRC_PATH &&\
	git checkout ${KONG_VERSION} &&\
	make dev

# final preparation
ENV PATH $PATH:/usr/local/bin:/usr/local/openresty/bin:/opt/stap/bin:/usr/local/stapxx:/usr/local/openresty/nginx/sbin
ENV KONG_LOG_LEVEL debug
ENV KONG_PROXY_ACCESS_LOG /proc/1/fd/1
ENV KONG_PROXY_ERROR_LOG /proc/1/fd/2
ENV KONG_ADMIN_ACCESS_LOG /proc/1/fd/2
ENV KONG_ADMIN_ERROR_LOG /proc/1/fd/2
ENV KONG_PREFIX /prefix
ENV KONG_LUA_SSL_TRUSTED_CERTIFICATE /etc/ssl/certs/ca-certificates.crt
ENV KONG_LUA_SSL_VERIFY_DEPTH 2

ENV KONG_LUA_PATH /usr/local/share/lua
ENV KONG_LUA_VERSION 5.1
ENV KONG_TEMP_DIRECTORY /tmp/kong
ENV KONG_INSTALLED_CUSTOM_PLUGINS_LIST /installed-plugins
ENV MOBDEBUG_SERVER localhost
ENV MOBDEBUG_CONTEXT access
ENV MOBDEBUG_ADD_LUA_PATH /opt/zbstudio/lualibs/?/?.lua;/opt/zbstudio/lualibs/?.lua
ENV MOBDEBUG_ADD_LUA_CPATH /opt/zbstudio/linux/x86/?.so;/opt/zbstudio/bin/linux/x86/clibs/?.so

COPY ./assets /
RUN chmod +x /entrypoint.sh  &&\
	chmod +x /install-plugins.sh && \
	mv ${KONG_LUA_PATH}/${KONG_LUA_VERSION} ${KONG_LUA_PATH}/${KONG_LUA_VERSION}-template

ENTRYPOINT ["/entrypoint.sh" ]


# fix locale warning
ENV LC_ALL en_US.UTF-8
ENV LC_CTYPE en_US.UTF-8
RUN echo "LC_CTYPE=\"$LC_ALL\"" >> /etc/default/locale &&\
	echo "LC_ALL=\"$LC_CTYPE\"" >> /etc/default/locale

# install plugin and move lua to temporary directory. 
# the /entrypoint.sh will sync the temporary directory to the mounted-volume so that all of its content will be available to host system for debugging purpose
ONBUILD RUN ln -s ${KONG_LUA_PATH}/${KONG_LUA_VERSION}-template/ ${KONG_LUA_PATH}/${KONG_LUA_VERSION}
ONBUILD ENV KONG_TEMP_PLUGIN_DIRECTORY ${KONG_TEMP_DIRECTORY}/plugins
ONBUILD COPY . ${KONG_TEMP_PLUGIN_DIRECTORY}
ONBUILD COPY ./kong/plugins ${KONG_SRC_PATH}/kong/plugins
ONBUILD COPY ./spec ${KONG_SRC_PATH}/spec
ONBUILD RUN /install-plugins.sh 1>&2
ONBUILD RUN rm ${KONG_LUA_PATH}/${KONG_LUA_VERSION}

# finalization
ONBUILD VOLUME ${KONG_LUA_PATH}/${KONG_LUA_VERSION} ${KONG_PREFIX}
ONBUILD EXPOSE 8000 8443 8001 8444
ONBUILD WORKDIR ${KONG_LUA_PATH}/${KONG_LUA_VERSION}
ONBUILD CMD ["./bin/kong", "start",  "-vv", "-c", "./bin/kong.conf" ]
