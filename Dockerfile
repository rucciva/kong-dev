FROM ubuntu:16.04

# docker images for debugging kong plugin
# based on http://lua-programming.blogspot.co.id/2015/12/how-to-debug-kong-plugins-on-windows.html and https://github.com/Kong/kong-vagrant

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
		perl 

# fix locale warning
ENV LC_ALL en_US.UTF-8
ENV LC_CTYPE en_US.UTF-8
RUN echo "LC_CTYPE=\"$LC_ALL\"" >> /etc/default/locale &&\
 	echo "LC_ALL=\"$LC_CTYPE\"" >> /etc/default/locale

# install systemtap
# https://openresty.org/en/build-systemtap.html
RUN apt-get install -y \
		build-essential \
		zlib1g-dev \
		elfutils \
		libdw-dev \
		gettext &&\
  	wget -q http://sourceware.org/systemtap/ftp/releases/systemtap-3.0.tar.gz &&\
  	tar -xf systemtap-3.0.tar.gz &&\
  	cd systemtap-3.0/ &&\
  	./configure \
	  	--prefix=/opt/stap \
		--disable-docs \
        --disable-publican \
		--disable-refdocs \
		CFLAGS="-g -O2" &&\
  	make &&\
  	make install &&\
  	rm -rf ./systemtap-3.0 systemtap-3.0.tar.gz &&\
	cd /usr/local &&\
	git clone https://github.com/openresty/stapxx.git &&\
  	git clone https://github.com/openresty/openresty-systemtap-toolkit.git &&\
  	git clone https://github.com/brendangregg/FlameGraph.git &&\
  	git clone https://github.com/wg/wrk.git &&\
  		cd wrk &&\
		make &&\
		cp ./wrk /usr/local/bin/ 

# install kong and prepare development environment
ARG KONG_VERSION
ENV KONG_VERSION ${KONG_VERSION:-0.13.0}
ENV KONG_SRC_PATH /usr/local/src/kong 
RUN echo "Fetching and installing Kong..." &&\
	set +o errexit &&\
	wget -q -O kong.deb "https://bintray.com/kong/kong-community-edition-deb/download_file?file_path=dists%2Fkong-community-edition-${KONG_VERSION}.trusty.all.deb" &&\
	if [ ! $? -eq 0 ];  then \
  		# 0.10.3 and earlier are on Github
  		echo "failed downloading from BinTray, trying Github..." &&\
  		set -o errexit &&\
  		wget -q -O kong.deb https://github.com/Kong/kong/releases/download/$KONG_VERSION/kong-$KONG_VERSION.precise_all.deb; \
	fi &&\
	set -o errexit &&\
	dpkg -i kong.deb &&\
	rm kong.deb &&\
	git clone https://github.com/Kong/kong $KONG_SRC_PATH &&\
	cd $KONG_SRC_PATH &&\
	git checkout ${KONG_VERSION} &&\
	make dev

# install zerobrane
ARG ZEROBRANE_VERSION 
ENV ZEROBRANE_VERSION ${ZEROBRANE_VERSION:-1.70}
RUN apt-get install -y sudo &&\
	mkdir -p /tmp/zerobrane/ &&\
	curl https://download.zerobrane.com/ZeroBraneStudioEduPack-${ZEROBRANE_VERSION}-linux.sh -o /tmp/zerobrane/zerobrane.sh &&\
	chmod +x /tmp/zerobrane/zerobrane.sh &&\
	/tmp/zerobrane/zerobrane.sh

# final preparation
ENV PATH $PATH:/usr/local/bin:/usr/local/openresty/bin:/opt/stap/bin:/usr/local/stapxx:/usr/local/openresty/nginx/sbin
ENV KONG_LOG_LEVEL debug
ENV KONG_PROXY_ACCESS_LOG /proc/1/fd/1
ENV KONG_PROXY_ERROR_LOG /proc/1/fd/2
ENV KONG_ADMIN_ACCESS_LOG /proc/1/fd/2
ENV KONG_ADMIN_ERROR_LOG /proc/1/fd/2
ENV KONG_PREFIX /prefix

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
	chmod +x /install-plugins.sh

# install plugin and move lua to temporary directory. 
# the /entrypoint.sh will sync the temporary directory to the mounted-volume so that all of its content will be available to host system for debugging purpose
ONBUILD ENV KONG_TEMP_PLUGIN_DIRECTORY ${KONG_TEMP_DIRECTORY}/plugins
ONBUILD COPY . ${KONG_TEMP_PLUGIN_DIRECTORY}
ONBUILD COPY . ${KONG_SRC_PATH}
ONBUILD RUN /install-plugins.sh 1>&2 &&\
	mv ${KONG_LUA_PATH}/${KONG_LUA_VERSION} ${KONG_LUA_PATH}/${KONG_LUA_VERSION}-template

# finalization
ONBUILD VOLUME ${KONG_LUA_PATH}/${KONG_LUA_VERSION} ${KONG_PREFIX}
ONBUILD EXPOSE 8000 8443 8001 8444
ONBUILD WORKDIR ${KONG_LUA_PATH}/${KONG_LUA_VERSION}
ONBUILD ENTRYPOINT ["/entrypoint.sh" ]
ONBUILD CMD ["./bin/kong", "start",  "-vv", "-c", "./bin/kong.conf" ]
