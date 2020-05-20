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

FROM php:7.4-apache AS prod
# install PHP extensions
RUN docker-php-ext-install \
    pdo_mysql
# update apache configs to point to Laravel's public sub-directory as document root
ENV APACHE_DOCUMENT_ROOT=/var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf \
    && sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf
# mod_rewrite for URL rewrite and mod_headers for .htaccess extra headers like Access-Control-Allow-Origin-
RUN a2enmod rewrite headers
# add project files
WORKDIR /var/www/html
COPY . ./
COPY --from=composer /app/vendor/ ./vendor/
COPY --from=node /app/public/js/ ./public/js/
COPY --from=node /app/public/css/ ./public/css/
COPY --from=node /app/mix-manifest.json ./mix-manifest.json
RUN chown -R www-data:www-data ./
# expose port 80 and start apache
EXPOSE 80
CMD ["apache2-foreground"]

###########################################################
# Development application
###########################################################

FROM prod AS dev
# install Linux packages
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

# make prod the default stage
FROM prod
