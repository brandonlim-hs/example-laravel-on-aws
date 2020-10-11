###########################################################
# PHP dependencies
###########################################################

FROM composer:latest AS composer
WORKDIR /app
# copy resources for composer install
# database directory for composer autoload
COPY database/ ./database/
COPY composer.* ./
RUN composer install \
    --ignore-platform-reqs \
    --no-dev \
    --no-interaction \
    --no-plugins \
    --no-progress \
    --no-scripts \
    --no-suggest \
    --optimize-autoloader \
    --prefer-dist

###########################################################
# Front end dependencies
###########################################################

FROM node:latest AS node
WORKDIR /app
# copy resources for npm install
COPY resources/js/ ./resources/js/
COPY resources/sass/ ./resources/sass/
COPY package.json package-lock.json webpack.mix.js ./
RUN mkdir -p public && npm install && npm run prod

###########################################################
# Production application
###########################################################

FROM php:7.4-fpm AS prod
# install PHP extensions
RUN docker-php-ext-install \
    pdo_mysql
# add project files
WORKDIR /var/www/html
COPY . ./
COPY --from=composer /app/vendor/ ./vendor/
COPY --from=node /app/public/js/ ./public/js/
COPY --from=node /app/public/css/ ./public/css/
COPY --from=node /app/mix-manifest.json ./mix-manifest.json
# configure non-root user
RUN groupmod -o -g 1000 www-data && \
    usermod -o -u 1000 -g www-data www-data
RUN chown -R www-data:www-data ./
# change current user to www-data
USER www-data
# expose port 9000 and start php-fpm server
EXPOSE 9000
CMD ["php-fpm"]

###########################################################
# Development application
###########################################################

FROM prod AS dev
# install Linux packages
USER root
RUN apt-get update && apt-get install -y \
    git \
    unzip \
    zip
# install composer on dev container only
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer
# install nodejs on dev container only
RUN curl -sL https://deb.nodesource.com/setup_14.x | bash - \
    && apt-get update && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*
# change current user to www-data
USER www-data

###########################################################
# Nginx web server
###########################################################

FROM nginx:alpine AS nginx
# remove default configuration
RUN rm /etc/nginx/conf.d/default.conf
# copy configuration
COPY .docker/nginx/conf.d/ /etc/nginx/conf.d/
# copy project files
COPY --from=prod /var/www/html /var/www/html