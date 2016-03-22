## Introduction
This Dockerfile will build a container image for nginx with php-fpm for web development and webapps. It supports templating, automated cloning from git, installation of [Composer](https://getcomposer.org/) and the installation of dependencies using Composer. The image is based on CentOS 7, and was initally forked from [this repository](https://github.com/ngineered/nginx-php-fpm).

## Repositories

### GitHub
The source files for this project are available on GitHub: [https://github.com/TheKatastrophe](https://github.com/TheKatastrophe)

### Docker Hub
The Docker Hub page for this project can be found [here](https://hub.docker.com/r/katastrophe/nginx-php-fpm/).

## Usage

### Pulling from Docker Hub
To pull this Dockerfile from Docker Hub:

	docker pull katastrophe/nginx-php-fpm

### Building from source
You can build this container from source with:

	git clone https://github.com/TheKatastrophe/nginx-php-fpm.git
	docker build -t katastrophe/nginx-php-fpm:latest .

### Running
Run the container with minimal configuration and options:

	docker run --name <container_name> -p 8080:80 -d -h <container_hostname> katastrophe/nginx-php-fpm

This will run the container, and you can access the web server by browsing to http://docker-host:8080

### Other options

#### Linking volumes

Syntax: `-v /host/path:/container/path`

You can use Docker to link a path within the container to a path on the host. For example, to expose the web server's document root on the Docker host at `/opt/website`, you could use:

	docker run --name <container_name> -p 8080:80 -d -h <container_hostname> -v /opt/website:/usr/share/nginx/html katastrophe/nginx-php-fpm

#### Git integration

Syntax: `-e 'GIT_REPO=git@git-server:repository.git' -e 'GIT_NAME=Mary' -e 'GIT_EMAIL=mary@company.tld' -e 'GIT_BRANCH=master'`

This container supports automatically cloning a git repository upon deploy. It also provides a `pull` and a `push` script for automatically pushing to/pulling from git from within the container.

There are four environment variables that can be set for this:

- `GIT_REPO`: The URL to the Git repository. This can be an SSH URL (`git@git-server:repository.git`) or an HTTP URL (`http://git-server/repository.git`). Be sure to read below about Git authentication. If `GIT_REPO` is specified, it will be cloned upon deploy.
- `GIT_EMAIL`: This is optional, but will set the email address used in commits made within this container.
- `GIT_NAME`: This is also optional, but will set the name used in commits made within this container.
- `GIT_BRANCH`: This is also optional, but will be used to specify which branch should be used for the git repository being cloned.

##### Notes on Git authentication

If specifying a HTTP URL that points to a public repository not requiring authentication, nothing further needs to be done. If authentication is required, I recommend using an SSH URL and providing an SSH key to be used for the deploy. 

This can be done using linked volumes (see above): before deploying the container, create a folder on the Docker host, such as `/opt/deploy` and create a file called `id_rsa` in it containing the private key used to authenticate to the Git host. Then link `/opt/deploy` on the host to `/root/.ssh` within the container using these flags: `-v /opt/deploy:/root/.ssh`.

**It is important** that you then set the permissions on the key correctly: `chmod 0600 /opt/deploy/id_rsa` or the key will not be used. The `start.sh` script, when the container is deployed, will set the permissions on the key if it exists, but if the key is replaced/changed, you need to ensure those permissions are maintained.

##### Pushing and pulling

There are two scripts available that make it easy to push and pull to/from your repository from the container or Docker host: `/usr/bin/push` and `/usr/bin/pull`. From within the container, you can just run `push` or `pull`. From the Docker host, you'd run:

	docker exec -t -i <container_name> /usr/bin/push

or

	docker exec -t - i <container_name> /usr/bin/pull

#### Composer

Composer is automatically installed within the container at `/usr/bin/composer` and can be run from within the container as `composer`. For example:

	cd /usr/share/nginx/html
	composer install

The container can also automatically run `composer install` to install requried dependencies.

Syntax: `-e 'RUN_COMPOSER=true'`

If `RUN_COMPOSER` is set to true as an environment variable using the `-e` flag, `composer install` will automatically be run within the document root.

#### PHP Errors

By default, PHP errors are logged but not displayed to the end user in the browser. To change this default, you can set the `ERRORS` environment variable to `true`.

Syntax: `-e 'ERRORS=true'`

#### PHP Timezone

PHP requires a timezone to be set explicitly, so we pass this in using the `PHPTZ` environment variable. If this is not specified, it will be defaulted to `Europe/London`.

Syntax: `-e 'PHPTZ=America/New_York'`

#### Container Linking and Templating

I will document these features in the near future, however for the moment I have not had the opportunity. They are currently, however, identical to the same features from the repository this project was forked from, so for usage information, see the relevant sections of [this README](https://github.com/ngineered/nginx-php-fpm/blob/master/README.md).