cd ~
#The real location of the project files
PROJECT_ROOT=/webroot/${PROJECT_ROOT_DIR}

PROJECT_NAME=$(basename ${PROJECT_ROOT_DIR})
#Location of the files
PROJECT_FILES_ROOT=${PROJECT_ROOT}/files
#Location for the nginx config
PROJECT_NGINX_ROOT=${PROJECT_ROOT}/nginx

#Home directory for non relative path fetching
HOME_DIR=${PWD}
#Location of the git rsa key
GIT_KEY_LOCATION=$HOME_DIR/gitkey
#The file for the proxy server to check if it exists. if this file does not
#exist, the proxy must ignore this server
UPCHECK_FILE_ROOT=${PROJECT_FILES_ROOT}/public
UPCHECK_FILE_LOCATION=${UPCHECK_FILE_ROOT}/upcheck

#Create the git key file
touch $GIT_KEY_LOCATION

#MKDIR the project directory
mkdir -p ${PROJECT_FILES_ROOT}
mkdir -p ${PROJECT_NGINX_ROOT}

mkdir -p $HOME_DIR/.ssh
touch $HOME_DIR/.ssh/config
cat <<EOF >> $HOME_DIR/.ssh/config
Host bitbucket.org github.com
  StrictHostKeyChecking no
  IdentityFile $GIT_KEY_LOCATION

EOF

if [ "$NGINX_SSL_CERT" != "" ]; then
  NGINX_SSL_CERT_STRING=""
  NGINX_SSL_CERT_FILENAME=${PROJECT_NGINX_ROOT}/${PROJECT_ROOT_DIR}_ssl.crt
  NGINX_SSL_KEY_FILENAME=${PROJECT_NGINX_ROOT}/${PROJECT_ROOT_DIR}_ssl.key
  sep=','

  case $NGINX_SSL_CERT in
    (*"$sep"*)
    NGINX_SSL_CERT_CONTENTS=${NGINX_SSL_CERT%%"$sep"*}
    NGINX_SSL_KEY_CONTENTS=${NGINX_SSL_CERT#*"$sep"}
    ;;
    (*)
    NGINX_SSL_CERT_CONTENTS=$NGINX_SSL_CERT
    NGINX_SSL_KEY_CONTENTS=
    ;;
  esac

   NGINX_SSL_CERT_CONTENTS=$( base64 --decode <<< "$NGINX_SSL_CERT_CONTENTS" )
   NGINX_SSL_KEY_CONTENTS=$( base64 --decode <<< "$NGINX_SSL_KEY_CONTENTS" )

   touch ${NGINX_SSL_CERT_FILENAME}
   touch ${NGINX_SSL_KEY_FILENAME}

   echo -e "$NGINX_SSL_CERT_CONTENTS" > ${NGINX_SSL_CERT_FILENAME}
   echo -e "$NGINX_SSL_KEY_CONTENTS" > ${NGINX_SSL_KEY_FILENAME}

  read -r -d '' NGINX_SSL_CERT_STRING <<EOF

  ssl on;
  ssl_certificate ${NGINX_SSL_CERT_FILENAME};
  ssl_certificate_key ${NGINX_SSL_KEY_FILENAME};

  ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
EOF

fi



#Remove the upcheck document, we do not care if the document does not exist
rm $UPCHECK_FILE_LOCATION 2> /dev/null

#change our working directory to project root
cd ${PROJECT_FILES_ROOT}

generateApiNginxConfig () {

CORS_ORIGIN="("
  while IFS=' ' read -ra ADDR; do
        for i in "${ADDR[@]}"; do
            # process "$i"
            CORS_ORIGIN="${CORS_ORIGIN}${i}|"
        done
   done <<< "$NGINX_CONF_CORS_ORIGINS"

   #remove the last pipe simbol and replace with )
   CORS_ORIGIN=$( echo "$CORS_ORIGIN" | rev | cut -c 2- | rev )
   CORS_ORIGIN="${CORS_ORIGIN})"

  cat <<EOF > ${PROJECT_NGINX_ROOT}/nginx-site.conf

  server {
      listen   80; ## listen for ipv4; this line is default and implied
      listen   443; ## listen for ipv4; this line is default and implied
  #   listen   [::]:80 default ipv6only=on; ## listen for ipv6

      root /webroot/${PROJECT_ROOT_DIR}/files/public;
      index index.php index.html;

      server_name ${NGINX_CONF_SERVER_NAME};

      ${NGINX_SSL_CERT_STRING}

      # Add stdout logging
      error_log /proc/self/fd/2 info;
      access_log /proc/self/fd/2;

      location / {
          # First attempt to serve request as file, then
          # as directory, then fall back to index.html
          try_files \$uri \$uri/ /index.php?q=\$uri&\$args;
      }

      #error_page 404 /404.html;
      # redirect server error pages to the static page /50x.html
      #
      error_page 500 502 503 504 /50x.html;

      location = /50x.html {
          root /usr/share/nginx/html;
      }

      # pass the PHP scripts to FastCGI server listening on 127.0.0.1:9000
      #
      location ~ \.php\$ {
          if (\$http_origin ~* (http(s)?\:\/\/(.*)($CORS_ORIGIN)(:([0-9]*))?)){
              more_set_headers 'Access-Control-Allow-Origin: \$http_origin';
              more_set_headers 'Access-Control-Allow-Methods GET,POST,OPTIONS,PUT,DELETE,PATCH';
              more_set_headers 'Access-Control-Allow-Credentials true';
              more_set_headers 'Access-Control-Allow-Headers Origin,Content-Type,Accept,Authorization';
          }

          try_files \$uri =404;
          fastcgi_split_path_info ^(.+\.php)(/.+)\$;
          fastcgi_pass unix:/var/run/php5-fpm.sock;
          fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
          fastcgi_param SCRIPT_NAME \$fastcgi_script_name;
          fastcgi_index index.php;
          fastcgi_buffer_size 128k;
          fastcgi_buffers 256 16k;
          fastcgi_busy_buffers_size 256k;
          fastcgi_temp_file_write_size 256k;
          include fastcgi_params;
      }

      location ~* \.(jpg|jpeg|gif|png|css|js|ico|xml)$ {
          expires 5d;
      }

      # deny access to . files, for security
      #
      location ~ /\. {
          log_not_found off;
          deny all;
      }
  }
EOF
}

generateWebNginxConfig () {
  cat <<EOF > ${PROJECT_NGINX_ROOT}/nginx-site.conf

  server {
  listen   80; ## listen for ipv4; this line is default and implied
  listen   443; ## listen for ipv4; this line is default and implied
# listen   [::]:80 default ipv6only=on; ## listen for ipv6

  root /webroot/${PROJECT_ROOT_DIR}/files/public;
  index index.html;

  server_name ${NGINX_CONF_SERVER_NAME};

  ${NGINX_SSL_CERT_STRING}

  # Add stdout logging
  error_log /proc/self/fd/2 info;
  access_log /proc/self/fd/2;

  location / {
    # First attempt to serve request as file, then
    # as directory, then fall back to index.html
    try_files \$uri \$uri/ /index.html;
  }

  #error_page 404 /404.html;

  # redirect server error pages to the static page /50x.html
  #
  error_page 500 502 503 504 /50x.html;
  location = /50x.html {
    root /usr/share/nginx/html;
  }

  location ~* \.(jpg|jpeg|gif|png|css|js|ico|xml)\$ {
                expires           5d;
  }

  # deny access to . files, for security
  #
  location ~ /\. {
        log_not_found off;
        deny all;
  }

}
EOF
}

generateNodeNginxConfig () {



  cat <<EOF > ${PROJECT_NGINX_ROOT}/nginx-site.conf

  server {
  listen   80; ## listen for ipv4; this line is default and implied
  listen   443; ## listen for ipv4; this line is default and implied
  #listen   [::]:80 default ipv6only=on; ## listen for ipv6

  server_name ${NGINX_CONF_SERVER_NAME};

  ${NGINX_SSL_CERT_STRING}

  ssl_protocols TLSv1 TLSv1.1 TLSv1.2;

  # Add stdout logging

  error_log /proc/self/fd/2 info;
  access_log /proc/self/fd/2;

  # deny access to . files, for security
  #
  location ~ /\. {
        log_not_found off;
        deny all;
  }

  location / {
      proxy_pass http://nfnty-nodejs:3000;
      proxy_http_version 1.1;
      proxy_set_header Upgrade \$http_upgrade;
      proxy_set_header Connection 'upgrade';
      proxy_set_header Host \$host;
      proxy_cache_bypass \$http_upgrade;
  }


}
EOF
}

setupNginx() {
  NGINX_CONF_TYPE=$( echo "$NGINX_CONF_TYPE" | tr '[:upper:]' '[:lower:]' )

  case "$NGINX_CONF_TYPE" in
   "api") generateApiNginxConfig
   ;;
   "web") generateWebNginxConfig
   ;;
   "node") generateNodeNginxConfig
   ;;
esac
  DOCKER_CONTAINER_ID=$(docker ps | grep "${NGINX_ENV_TUTUM_CONTAINER_HOSTNAME}" | cut -c1-12)
  docker exec ${DOCKER_CONTAINER_ID} /bin/bash -c "nginx_enproject ${PROJECT_NAME}"
}

pullRepository() {
  echo "Pulling repository..."
  git reset --hard
  git pull
  rm -r ${PROJECT_FILES_ROOT}/data/cache/module-c*
}

cloneRepository() {
  echo "Cloning repository..."
  rm -rf $PROJECT_FILES_ROOT/*
  git clone ${GIT_REPO_URL} .

  setupNginx
  mkdir -p $PROJECT_FILES_ROOT/data/cache
  chmod -R 777 $PROJECT_FILES_ROOT/data

}

#If the GIT_SSH_KEY environment variable has been defined, use that rsa key
#To authenticate with git. IF it has not been defined, try to use the id_rsa
#From the user
if [ "$GIT_SSH_KEY" != "" ]; then
  echo "Using environment git ssh key"
  echo -e "$( base64 --decode <<< "$GIT_SSH_KEY" )" > $GIT_KEY_LOCATION
else
  echo "Using ssh key from home dir"
  cat $HOME_DIR/.ssh/id_rsa > $GIT_KEY_LOCATION
fi

#chmod 600 ${GIT_KEY_LOCATION}
#ssh-add ${GIT_KEY_LOCATION}

chmod 400 ${GIT_KEY_LOCATION}
#check if the project root is a valid git repository. if so, pull, if not, clone
if git rev-parse --git-dir > /dev/null 2>&1; then
  : # This is a valid git repository
  pullRepository
else
  : # this is not a git repository
  cloneRepository
fi

#Check if we should run composer install
if [ "$SHOULD_COMPOSER_INSTALL" = "1" ]; then
  echo "Generating composer auth.json..."
  mkdir -p $COMPOSER_HOME
  touch $COMPOSER_HOME/auth.json

  cat <<EOF > $COMPOSER_HOME/auth.json
  {
      "http-basic": {
          "packages.nfnty.nl": {
              "username": "$COMPOSER_PACKAGES_USERNAME",
              "password": "$COMPOSER_PACKAGES_PASSWORD"
          }
      },
      "github-oauth": {
          "github.com": "$COMPOSER_GITHUB_TOKEN"
      }
  }
EOF

  echo "Running Composer install..."
  composer install --no-dev
fi

if [ "$PHP_CONFIGS" != "" ]; then
  echo "creating php config files..."
  while IFS=',' read -ra ADDR; do
        for i in "${ADDR[@]}"; do
            # process "$i"
            sep=':'

            case $i in
              (*"$sep"*)
              FILENAME=${i%%"$sep"*}
              BASE_CONTENTS=${i#*"$sep"}
              ;;
              (*)
              FILENAME=$i
              BASE_CONTENTS=
              ;;
            esac

            DECODED_CONTENTS=$(echo $BASE_CONTENTS | base64 --decode)
            FILE_LOCATION="${PROJECT_FILES_ROOT}/config/autoload/${FILENAME}"
            touch $FILE_LOCATION
            echo -e "$DECODED_CONTENTS" > $FILE_LOCATION
        done
   done <<< "$PHP_CONFIGS"
fi

mkdir -p ${UPCHECK_FILE_ROOT}
touch $UPCHECK_FILE_LOCATION
#write the predefined string for the proxy to check on to the upcheck document
echo "i_appear_to_be_online" > $UPCHECK_FILE_LOCATION
exit 0
