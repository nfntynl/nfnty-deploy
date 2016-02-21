# Composer Docker Container
FROM composer/composer
ENV PROJECT_ROOT_DIR=""
ENV GIT_SSH_KEY=""
ENV GIT_REPO_URL=""
ENV SHOULD_COMPOSER_INSTALL="0"
ENV COMPOSER_PACKAGES_USERNAME=""
ENV COMPOSER_PACKAGES_PASSWORD=""
ENV COMPOSER_GITHUB_TOKEN=""
#base64 of config files formatted as config.local.php:{base64},config2.local.php:{base64}
ENV PHP_CONFIGS=""

#api or web
ENV NGINX_CONF_TYPE="api"
#space delimited list of server names to add to the nginx vhost
ENV NGINX_CONF_SERVER_NAME="api api.example.com"

#space delimited list of server addresses to be allowed cors access. everything beneath the address will be allowed
ENV NGINX_CONF_CORS_ORIGINS=".example.com .example.me .nfnty.nl localhost"
#OPTIONAL ssl certificate and key. two base64 hashes first the certficate, second the key, separated by a , (comma) example: {base64},{base64}
ENV NGINX_SSL_CERT=""
VOLUME ["/webroot"]

COPY /run.sh /tmp/

RUN chmod 777 /tmp/run.sh
ENTRYPOINT /bin/bash /tmp/run.sh
