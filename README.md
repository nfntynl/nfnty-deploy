# Docker deploy
## Summary
This container deploys projects automatically on docker run by cloning or pulling them from git and, based on the settings in the environment variables, does some extra stuff. This Docker stops after cloning, pulling and configuring.

In short, this container:
- Clones/pulls a github repo
- Generates nginx vhost config files and reloads the nginx container (ssl supported)
- Optionally saves php configuration files supplied in the environment variables
- Optionally runs composer install --no-dev on the project root

## Mount points

```
/var/run/docker.sock:/var/run/docker.sock:ro
/user/bin/docker:/usr/bin/docker
```

Two mandatory mount points for communicating with the host docker process. This container communicaties with nginx for reloading the nginx service in order to enable vhost config changes

```
/local/webroot/folder:/webroot
```

The deploy container will save all the project files inside the container's /webroot folder. Mount this folder on your host where you want all the project files to be.

## Environment variables
### PROJECT_ROOT_DIR
** Default value ** `""`

** Example ** `"web_project"`

Root directory and also the project name. Treat as a single folder. With the above example, all the project files will be inside /webroot/web_project

### GIT_SSH_KEY
** Default value ** `""`

** Example ** `"{base64 encoded private key file}"`

A base64 private key file to be used when cloning/pulling the git repository. Its public counterpart should be added as deployment key in the git repository to pull.

### GIT_REPO_URL
** Default value ** `""`

** Example ** `"git@bitbucket.org:example/mywebproject.git"`

Git ssh url to the repo to clone/pull

### SHOULD_COMPOSER_INSTALL
** Default value ** `"0"`

** Example ** `"1"`

If the value is not 0, the container will run `composer install --no-dev` on the project root.

### COMPOSER_PACKAGES_USERNAME
** Default value ** `""`

** Example ** `"username"`

Optional username for a private composer packages server composer could use for any private libraries

### COMPOSER_PACKAGES_PASSWORD
** Default value ** `""`

** Example ** `"password"`

Optional password for a private composer packages server composer could use for any private libraries

### COMPOSER_GITHUB_TOKEN
** Default value ** `""`

** Example ** `"oauthtoken"`

Oauth token composer should use when cloning libraries from github to get a higher ratelimit from GitHub.

### PHP_CONFIGS
** Default value ** `""`

** Example ** `"file1.config.php:{base64 contents},file2.config.php:{base64 contents}"`

When deploying a zend framework 2 application, add the different local config files in the order of `{filename}:{base64 contents},{filename}:{base64 contents}` The configuration files will be saved in {projectroot}/config/autoload/

### NGINX_CONF_TYPE
** Default value ** `"api"`

** Example ** `"web"`

Must be one of "api", "web" or "node"

Based on this variable, different nginx vhosts will be enabled on the nginx container

### NGINX_CONF_SERVER_NAME
** Default value ** `""`

** Example ** `"api api.example.com api.example.org"`

Mandatory variable to be put in the server_name of the nginx vhost config.

### NGINX_CONF_CORS_ORIGINS
** Default value ** `""`

** Example ** `" .example.com .example.org localhost"`

Origins to be allowed cors access to the api. If a leading dot is added, any subdomain from that domain will be allowed cors access. Also, any port will be allowed. so localhost:8080 will also get the cors headers sent.

### NGINX_SSL_CERT
** Default value ** `""`

** Example ** `"{base64},{base64}"`

When not equal to "", base64 decode the two strings, separated by a comma. The first one must be the ssl certificate, the second must be the ssl key.

(Supported ssl certificates: TLSv1 TLSv1.1 TLSv1.2)

```
docker run \
#remove yourself after completion
--rm \

#path to the parent directory from where the website should be stored on the host
-v /local/webroot/folder:/webroot \

#mandatory docker.sock and docker executable mounts for communication with the nginx container (reload)
-v /var/run/docker.sock:/var/run/docker.sock:ro \
-v /user/bin/docker:/usr/bin/docker \
--privileged=true \

#root dir name and project name of this web project (will result in all the project files being saved in /local/webroot/folder/web_project)
-e PROJECT_ROOT_DIR="web_project" \

#we are deploying a web, html only project, affects the nginx configuration
-e NGINX_CONF_TYPE="web" \

#server names to be set in the nginx vhost configuration
-e NGINX_CONF_SERVER_NAME="homepage example.com example.org" \

#Since this is not api, dont add ant Origins cors should be enabled from
-e NGINX_CONF_CORS_ORIGINS="" \

#base64 separated list of ssl certificate and key file contents
-e NGINX_SSL_CERT="YXNkCg==,YXNkZgo=" \

#no php files to add after deployment
-e PHP_CONFIGS="" \

#no composer install --no-dev to run after cloning/pulling
-e SHOULD_COMPOSER_INSTALL=0 \
#no private composer repo credentials
-e COMPOSER_PACKAGES_USERNAME="" \
-e COMPOSER_PACKAGES_PASSWORD="" \
-e COMPOSER_GITHUB_TOKEN="" \

#base64 encoded id_rsa private file. The public part of the identity file should be set as deployment key in the git repo
-e GIT_SSH_KEY="" \

#Url to the git repository to clone in the project_root_dir
-e GIT_REPO_URL="git@bitbucket.org:example/mywebproject.git" github.com/nfntynl/deploy
```
