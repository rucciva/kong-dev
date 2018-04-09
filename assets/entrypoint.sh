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

# configure testing environment
while read LINE; do
	IFS='=' read -ra CONF_LINE <<< "$LINE"
	CONF_KEY=$(echo -n "${CONF_LINE[0]#SPEC_KONG_}" | tr '[:upper:]' '[:lower:]' )
	CONF_VALUE=$(IFS='='; echo "${CONF_LINE[*]:1}")
    CONF_VALUE="${CONF_VALUE/\|/\\|}"
    sed -i '/^'"$CONF_KEY"' = /{h;s| = .*| = '"$CONF_VALUE"'|};${x;/^$/{s||'"$CONF_KEY"' = '"$CONF_VALUE"'|;H};x}' $KONG_SRC_PATH/spec/kong_tests.conf
done < <(env | grep 'SPEC_KONG_')

# execute command
export KONG_NGINX_DAEMON="off" 
echo "preparation done. Executing command: $@"
exec "$@"