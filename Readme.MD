# Docker Kong Mobdebug

Docker Onbuild image to help debugging kong plugin using mobdebug bundled with Zerobrane Studio based on [kong-vagrant](https://github.com/Mashape/kong-vagrant) and [this awesome tutorial](http://lua-programming.blogspot.co.id/2015/12/how-to-debug-kong-plugins-on-windows.html)

This images was designed to work with the `kong-plugin` [development template](https://git.rucciva.one/rucciva/kong-plugin). Please
checkout that repos as a template to start your kong's plugin development.

## Preparation

```bash
docker-compose up -d postgress && docker-compose logs -f postgress
# wait until it's ready and press Ctrl+C
docker-compose up migrator
docker-compose up -d kong
# add mockbin API
curl -i -X POST \
  --url http://localhost:8001/apis/ \
  --data 'name=mockbin' \
  --data 'upstream_url=http://mockbin.org/request' \
  --data 'uris=/'
# add mobdebug plugin
curl -i -X POST \
  --url http://localhost:8001/apis/mockbin/plugins/ \
  --data 'name=mobdebug'
# add your plugin
# try the mockbin API
curl -i http://localhost:8000
```

## Debugging via zerobrane

*Assuming you mount **$KONG_LUA_PATH/$KONG_LUA_VERSION** container path into **./volumes/kong/usr/local/share/lua/5.1**,*

1. Click "Project" > "Project Directory" > "choose" and poin the project directory to ***./volumes/kong/usr/local/share/lua/5.1***.

1. Click "Project" > "Start Debugger Server"

1. Invoke the mockbin API