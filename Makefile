APP_NAME ?= api
DOCKER_NETWORK ?= viparis

up:
	docker-compose up -d

down:
	docker-compose down

clear:
	docker-compose down -v

db-reset:
	docker-compose run --rm api bin/console doctrine:database:drop -n --if-exists --force
	docker-compose run --rm api bin/console doctrine:database:create -n
	docker-compose run --rm api bin/console doctrine:database:import vendor/wynd/api/data/test/dump/db_test.sql
	docker-compose run --rm api bin/console doctrine:migrations:migrate -n -e dev
	docker-compose run --rm api bin/console hautelook_alice:doctrine:fixtures:load -n -b WyndApiCoreBundle -b WyndBookingApiBundle -b WyndApiSupplierBundle --append --no-debug -e dev

install:
	@git submodule update --init --recursive --checkout --force
	@cp docker-compose.override.yml.dist docker-compose.override.yml
	@cp .env.dist .env
	@make init
	@make db-reset

test-unit:
	cp docker-compose.override.ci.yml.dist docker-compose.override.yml
	cp .env.dist .env
	docker-compose run  --no-deps --rm $(APP_NAME) composer install --no-scripts
	docker-compose run --no-deps --rm $(APP_NAME) vendor/bin/phpunit --no-coverage --testsuite unit


test-cs:
	cp api/app/config/parameters.yml.dist api/app/config/parameters.yml
	cp docker-compose.override.ci.yml.dist docker-compose.override.yml
	cp .env.dist .env
	docker-compose run --no-deps --rm $(APP_NAME) composer install --no-scripts
	docker-compose run --no-deps --rm $(APP_NAME) bin/console lint:yaml app
	docker-compose run --no-deps --rm $(APP_NAME) bin/console lint:yaml src
	docker-compose run --no-deps --rm $(APP_NAME) bin/console lint:twig app
	docker-compose run --no-deps --rm $(APP_NAME) bin/console lint:twig src
	docker-compose run --no-deps --rm $(APP_NAME) vendor/bin/php-cs-fixer fix src --no-interaction --dry-run --diff -vvv --config=.php_cs --cache-file=.php_cs.cache --using-cache=no
	docker-compose run --no-deps --rm $(APP_NAME) "find src -type f -name '*.php' | xargs -I {} php -l {}"

fix-cs:
	docker-compose exec -u 1000 $(APP_NAME) vendor/bin/php-cs-fixer fix src -vvv --config=.php_cs --cache-file=.php_cs.cache

test-integration:
	cp docker-compose.override.ci.yml.dist docker-compose.override.yml
	cp .env.dist .env
	docker-compose up -d database
	docker-compose run --no-deps --rm -e "SYMFONY_ENV=test" $(APP_NAME) composer install
	docker-compose run --rm -v "${CURDIR}/api:/var/www/html" -v "${CURDIR}/docker/php70/wait-mysql.sh:/wait.sh" api /wait.sh
	docker-compose run --rm -w "/var/www/html" -v "${CURDIR}/api:/var/www/html" -v "${CURDIR}/docker/php70/generate-jwt.sh:/generate-jwt.sh" api /generate-jwt.sh
	docker-compose run --rm -e "SYMFONY_ENV=test" $(APP_NAME) vendor/bin/phpunit --no-coverage --testsuite integration


init:
	docker-compose run --rm api composer install --no-interaction
	docker-compose run --rm -w "/var/www/html" -v "${CURDIR}/api:/var/www/html" -v "${CURDIR}/docker/php70/generate-jwt.sh:/generate-jwt.sh" api /generate-jwt.sh

launch-proxy:
	docker run --network "${DOCKER_NETWORK}_default" --rm -it -v /tmp/.mitmproxy:/home/mitmproxy/.mitmproxy mitmproxy/mitmproxy