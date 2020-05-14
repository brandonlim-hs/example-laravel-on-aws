FROM php:7.4-apache

ARG APP_ENV
ENV APP_HOME /var/www/html

# install Linux packages
RUN apt-get update && apt-get install -y \
    git \
    unzip \
    zip

# install PHP extensions
RUN docker-php-ext-install \
    pdo_mysql

# update apache configs to point to Laravel's public sub-directory as document root
ENV APACHE_DOCUMENT_ROOT=/var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf \
    && sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# mod_rewrite for URL rewrite and mod_headers for .htaccess extra headers like Access-Control-Allow-Origin-
RUN a2enmod rewrite headers

# install composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# install nodejs
RUN curl -sL https://deb.nodesource.com/setup_14.x | bash - \
    && apt-get update && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# set working directory
WORKDIR $APP_HOME

# add project files
COPY . $APP_HOME/
RUN chown -R www-data:www-data $APP_HOME/

# install PHP dependencies
RUN bash -c \
    'if [[ "$APP_ENV" =~ .*prod.* ]]; \
    then composer install --no-interaction --no-progress --no-dev; \
    else composer install; \
    fi'

# install JS dependencies and compile frontend
RUN npm install \
    && bash -c \
    'if [[ "$APP_ENV" =~ .*prod.* ]]; \
    then npm run prod; \
    else npm run dev; \
    fi'

# expose port 80 and start apache
EXPOSE 80
CMD ["apache2-foreground"]
