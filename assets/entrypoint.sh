#!/bin/bash

set -e

# prepare mountable lua folder for debugging purpose
rsync -a ${KONG_LUA_PATH}/${KONG_LUA_VERSION}-template/ ${KONG_LUA_PATH}/${KONG_LUA_VERSION}
if [ ${KONG_LUA_PATH} != "/usr/local/share/lua" ]; then
    rm -f ${KONG_LUA_PATH}/${KONG_LUA_VERSION}
    ln -s ${KONG_LUA_PATH}/${KONG_LUA_VERSION} /usr/local/share/lua 
fi
mkdir -p ${KONG_LUA_PATH}/${KONG_LUA_VERSION}/bin/ 
cp /usr/local/bin/kong ${KONG_LUA_PATH}/${KONG_LUA_VERSION}/bin/kong 
cp /etc/kong/kong.conf.default ${KONG_LUA_PATH}/${KONG_LUA_VERSION}/bin/kong.conf

# automatically add installed plugin in environment
if [ -f $KONG_INSTALLED_CUSTOM_PLUGINS_LIST ]; then
    export KONG_CUSTOM_PLUGINS="$(cat $KONG_INSTALLED_CUSTOM_PLUGINS_LIST)"
fi

# execute command
export KONG_NGINX_DAEMON="off" 
echo "preparation done. Executing command: $@"
exec "$@"