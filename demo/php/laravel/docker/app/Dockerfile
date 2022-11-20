FROM php:7.4.33-cli

ADD php.ini /usr/local/etc/php/

RUN apt-get update
RUN apt-get install -y gnupg git zip unzip vim libpng-dev libpq-dev
RUN docker-php-ext-install pdo_mysql

RUN curl -sS https://pkg.contrastsecurity.com/api/gpg/key/public | apt-key add -
RUN echo "deb https://pkg.contrastsecurity.com/debian-public/ $(sed -rne 's/^VERSION_CODENAME=(.*)$/\1/p' /etc/*ease) contrast" | tee /etc/apt/sources.list.d/contrast.list
RUN echo "deb https://pkg.contrastsecurity.com/debian-public/ all contrast" | tee -a /etc/apt/sources.list.d/contrast.list
RUN apt-get update && apt-get install contrast-php-agent
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

RUN mkdir /etc/contrast
COPY contrast_security.yaml /etc/contrast

RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
RUN php composer-setup.php --install-dir=/usr/local/bin --filename=composer
RUN rm composer-setup.php

RUN cd && git clone https://github.com/laravel/quickstart-basic quickstart
COPY db.env /root/quickstart/.env
RUN cd /root/quickstart && composer install
RUN chmod -R 777 /root/quickstart/storage

WORKDIR /root/quickstart
CMD ["php", "artisan", "serve", "--host", "0.0.0.0", "--port", "8000"]
