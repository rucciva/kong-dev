#!/bin/bash

set -e

cd $KONG_TEMP_PLUGIN_DIRECTORY
installed="bundled,mobdebug"
for f in `ls | grep rockspec`; do 
    if [ -f $f ]; then 
        PLUGIN_NAME=`echo $f |  sed -n "s/kong-plugin-\(.*\)-[0-9]*\.[0-9]*\.[0-9]*-[0-9]*\.rockspec$/\1/p"`
        echo "installing $PLUGIN_NAME"
        luarocks make $f   
        installed="${installed},${PLUGIN_NAME}"
    fi;
done

# record installed plugin for later use
echo "Installed Custom Plugins: $installed"
echo $installed >> $KONG_INSTALLED_CUSTOM_PLUGINS_LIST

