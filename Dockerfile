FROM php:8.1-apache

LABEL maintainer="sebastijan.sakac@icloud.com"
LABEL php_version="8.1"
LABEL magento_version="2.4.4"
LABEL description="Magento 2.4.4 with PHP 8.1"

ENV MAGENTO_VERSION 2.4.4
ENV INSTALL_DIR /var/www/html
ENV COMPOSER_HOME /var/www/.composer/

COPY ./auth.json $COMPOSER_HOME
RUN curl -sS https://getcomposer.org/installer | php \
    && mv composer.phar /usr/local/bin/composer \
    && apt-get update && apt-get install -y  \
    libmcrypt-dev \
    default-mysql-client \
    openssl \
    libpq-dev \
    libzip4 \
    zip \
    p7zip-full \
    unzip \
    vim \
    autoconf \
    build-essential \
    apt-utils \
    zlib1g-dev \
    libzip-dev \
    libmagick++-dev \
    libmagickwand-dev \
    libpq-dev \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    wget \
    libzip-dev \
    zip \
    cron \
    libxslt-dev \
    && docker-php-ext-install gd \
    && docker-php-ext-install intl \
    && docker-php-ext-configure gd --with-jpeg=/usr/include/ --with-freetype=/usr/include/ --with-freetype --enable-gd \
    && docker-php-ext-install zip \
    && docker-php-ext-install mysqli pdo pdo_mysql \
    && docker-php-ext-install soap \
    && docker-php-ext-install xsl \
    && docker-php-ext-install sockets \
    && docker-php-ext-install bcmath \
    && docker-php-ext-configure gd --enable-gd --with-freetype --with-jpeg \
    && docker-php-ext-install bcmath gd \
    &&yes '' | pecl install mcrypt-1.0.5 \
    && echo 'extension=mcrypt.so' > /usr/local/etc/php/conf.d/mcrypt.ini \
    &&chsh -s /bin/bash www-data \
    && cd /tmp && \
    curl https://codeload.github.com/magento/magento2/tar.gz/$MAGENTO_VERSION -o $MAGENTO_VERSION.tar.gz && \
    tar xvf $MAGENTO_VERSION.tar.gz && \
    mv magento2-$MAGENTO_VERSION/* magento2-$MAGENTO_VERSION/.htaccess $INSTALL_DIR \
    && chown -R www-data:www-data /var/www \
    && su - www-data -c "cd $INSTALL_DIR && composer install" \
    && su - www-data -c "cd $INSTALL_DIR && composer config repositories.magento composer https://repo.magento.com/" \
    && cd $INSTALL_DIR \
    && find . -type d -exec chmod 770 {} \; \
    && find . -type f -exec chmod 660 {} \; \
    && chmod u+x bin/magento \
    && a2enmod rewrite \
    && echo "memory_limit=2048M" > /usr/local/etc/php/conf.d/memory-limit.ini \
    && apt-get clean  \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY ./install-magento /usr/local/bin/install-magento
COPY ./install-sampledata /usr/local/bin/install-sampledata
ADD crontab /etc/cron.d/magento2-cron

RUN chmod +x /usr/local/bin/install-magento \
    && chmod +x /usr/local/bin/install-sampledata \
    && chmod 0644 /etc/cron.d/magento2-cron \
    && crontab -u www-data /etc/cron.d/magento2-cron \
    && chown -R www-data:www-data /var/www

VOLUME $INSTALL_DIR
