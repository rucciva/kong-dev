# Hi

Docker Onbuild images to help debugging kong plugin.


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
# try the API
curl -i http://localhost:8000
```

## Debugging via zerobrane

choose "Project" > "Project Directory" > "choose" and poin the project directory to ./volumes/kong/kong/lua/5.1
choose "Project" > "Start Debugger Server"
invoke the mockbin API

## Debugging other plugin

mount yout plugin into /tmp/kong, install it, add the plugin name into KONG_CUSTOM_PLUGINS environment variables in docker-compose.yml, and then recreate kong container.