#!/usr/bin/env bash

# This is a single container setup, the first (and only) container contains the Laravel project
CONTAINER_ID=$(docker ps -a -q | head -n 1)

# Run Laravel's migration command
docker exec $CONTAINER_ID php artisan migrate --force
