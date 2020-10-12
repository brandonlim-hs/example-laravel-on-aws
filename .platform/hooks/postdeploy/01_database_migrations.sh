#!/usr/bin/env bash

# Run Laravel's migration command
docker exec app php artisan migrate --force
