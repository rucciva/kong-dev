#!/bin/bash

set -e

if [ -n "$KONG_DEV_PLUGIN_NAME"  ]; then
    # install single plugins
    cd ${KONG_TEMP_PLUGIN_DIRECTORY}/${KONG_DEV_PLUGIN_NAME}
    luarocks make
    installed=$KONG_DEV_PLUGIN_NAME

else
    # install multiple plugins
    # each plugins should be contained under the folder named with it's name
    cd ${KONG_TEMP_PLUGIN_DIRECTORY}
    installed=""
    for i in $(ls -d */); do 
        cd ${KONG_TEMP_PLUGIN_DIRECTORY}/$i
        luarocks make
        
        if [ -n "$installed" ]; then
            installed="${installed},"
        fi
        installed="${installed}${i%%/}"
    done
fi

# record installed plugin for later use
echo "mobdebug,${installed}" > $KONG_INSTALLED_CUSTOM_PLUGINS_LIST
