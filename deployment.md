# Deployment

[![Deploy to Azure](http://azuredeploy.net/deploybutton.png)](https://azuredeploy.net/)

## Deploy with Docker

### Start CouchDB
```shell
$ docker run -d --name my-couchdb \
    -v /data/couchdb:/usr/local/var/lib/couchdb \
    klaemo/couchdb:1.6.1
$ # create a admin user with the password `secret`
$ # of course you can use you own username/password
$ docker run -it --rm \
    --link my-couchdb:couchdb \
    yxdhde/alpine-curl-git curl -X PUT \
    couchdb:5984/_config/admins/admin -d '"secret"'
$ # login with the admin user
$ docker run -it --rm \
    --link my-couchdb:couchdb \
    yxdhde/alpine-curl-git curl -X POST \
    -H 'Content-Type: application/x-www-form-urlencoded' \
    couchdb:5984/_session -d 'name=admin&password=secret'
```

### Build hoodie-app-tracker
```shell
$ docker build -t hoodie-app-tracker .
$ docker run -d -p 8080:8080 \
    --name my-app \
    --link my-couchdb:couchdb \
    hoodie-app-tracker
```

##### Or use the prebuilt Docker image
```shell
$ docker run -d -p 8080:8080 \
    --name my-app \
    --link my-couchdb:couchdb \
    -e hoodie_dbUrl=http://admin:secret@couchdb:5984/ \
    hoodiehq/hoodie-app-tracker
```

### Continuous deployment with Docker Hub
```shell
$ docker run -d --name hub-webhook \
    -e VIRTUAL_HOST=webhook-deploy.my-domain.com \
    -e DEFAULT_PARAMS='--restart=always -p 8080:8080 --link my-couchdb:couchdb' \
    -e DEFAULT_TOKEN=my-webhook-token \
    -v /var/run/docker.sock:/var/run/docker.sock:ro \
    christophwitzko/docker-hub-webhook
```

Set up a webhook on Docker Hub with the URL `http://deploy-webhook.my-domain.com/my-webhook-token`.

## Example with a reverse proxy
This example is deployed at [tracker.hood.ie](https://tracker.hood.ie).

#### Reverse Proxy with Letsencrypt
The following two docker commands start a Nginx reverse proxy with automatic certificate creation and renewal.
```shell
$ docker run -d -p 80:80 -p 443:443 \
    --name nginx-proxy \
    -v /data/certs:/etc/nginx/certs:ro \
    -v /etc/nginx/vhost.d \
    -v /usr/share/nginx/html \
    -v /var/run/docker.sock:/tmp/docker.sock:ro \
    jwilder/nginx-proxy
$ docker run -d --name letsencrypt-companion \
    --volumes-from nginx-proxy \
    -v /data/certs:/etc/nginx/certs:rw \
    -v /var/run/docker.sock:/var/run/docker.sock:ro \
    jrcs/letsencrypt-nginx-proxy-companion
```
#### Start CouchDB
This step is equivalent to [Start CouchDB](#start-couchdb).

#### Docker Hub webhook deployment
This starts the webhook server. If it receives a webhook it pulls the updated image and restarts the container. More info [here](https://github.com/christophwitzko/docker-hub-webhook).
```shell
$ docker run -d --name hub-webhook \
    -e VIRTUAL_HOST=webhook-deploy.hood.ie \
    -e LETSENCRYPT_HOST=webhook-deploy.hood.ie \
    -e LETSENCRYPT_EMAIL=your@email.com \
    -e DEFAULT_PARAMS='--restart=always -e hoodie_dbUrl=http://admin:secret@couchdb:5984/ -e VIRTUAL_HOST=tracker.hood.ie -e LETSENCRYPT_HOST=tracker.hood.ie -e LETSENCRYPT_EMAIL=your@email.com --link my-couchdb:couchdb' \
    -e DEFAULT_TOKEN=my-secret-token \
    -v /var/run/docker.sock:/var/run/docker.sock:ro \
    christophwitzko/docker-hub-webhook
```
