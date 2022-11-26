FROM drupal:latest

ADD php.ini /usr/local/etc/php/

RUN apt-get update
RUN apt-get install -y gnupg git zip unzip vim libpng-dev libpq-dev libzip-dev
RUN docker-php-ext-install pdo_mysql gd zip

RUN curl -sS https://pkg.contrastsecurity.com/api/gpg/key/public | apt-key add -
RUN echo "deb https://pkg.contrastsecurity.com/debian-public/ $(sed -rne 's/^VERSION_CODENAME=(.*)$/\1/p' /etc/*ease) contrast" | tee /etc/apt/sources.list.d/contrast.list
RUN echo "deb https://pkg.contrastsecurity.com/debian-public/ all contrast" | tee -a /etc/apt/sources.list.d/contrast.list
RUN apt-get update && apt-get install contrast-php-agent
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

RUN mkdir /etc/contrast
COPY contrast_security.yaml /etc/contrast

RUN composer global require drush/drush \
  && ln -s /root/.composer/vendor/bin/drush /usr/local/bin/drush \
  && drush --version
CMD ["apache2-foreground"]
