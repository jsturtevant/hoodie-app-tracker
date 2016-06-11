#!/bin/bash
docker run -d --name my-couchdb \
    -v /data/couchdb:/usr/local/var/lib/couchdb \
    klaemo/couchdb:1.6.1
# create a admin user with the password 
# of course you can use you own username/password
pass=$1
docker run --rm \
    --link my-couchdb:couchdb \
    yxdhde/alpine-curl-git curl -X PUT \
    couchdb:5984/_config/admins/admin -d '"'$pass'"'
# login with the admin user
docker run --rm \
    --link my-couchdb:couchdb \
    yxdhde/alpine-curl-git curl -X POST \
    -H 'Content-Type: application/x-www-form-urlencoded' \
    couchdb:5984/_session -d 'name=admin&password='$pass
docker run -d -p 8080:8080 \
    --name my-app \
    --link my-couchdb:couchdb \
    -e hoodie_dbUrl=http://admin:$pass@couchdb:5984/ \
    hoodiehq/hoodie-app-tracker
