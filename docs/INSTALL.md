# How to install Caras-Framework

[Install on macOS](#install-on-macos)

[Install on Kali Linux](#install-on-kali-linux)

[Install on docker](#install-on-docker)


# Install on macOS

## Requirements

Xcode and HomeBrew are necessary to install the framework on macOS.

* [Xcode](https://itunes.apple.com/app/xcode/id497799835)
* [HomeBrew](https://brew.sh/)

Though it's not indispensable to the framework, it is recommended to install docker to run PostgreSQL. In the following procedure, docker will be used.

* [Docker for Mac](https://www.docker.com/docker-mac)

## Install

1. Install dependent packages

    ```bash
    $ brew install rbenv rbenv-gemset libxml2 readline postgresql libmagic yarn nmap
    $ brew link --force libxml2
    ```

    Add the setting to enable rbenv in .bash-profile.

    ```bash
    $ echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bash_profile
    $ echo 'eval "$(rbenv init -)"' >> ~/.bash_profile
    ```

2. Clone the repository

    Clone Caras-Framework and *TestSuite*.

    ```bash
    $ cd path/to/install
    $ git clone https://github.com/gsx-lab/caras-framework.git
    $ cd caras-framework
    $ git clone https://github.com/gsx-lab/caras-testsuite.git test_suites/default
    ```

3. Start the DBMS

    Start PostgreSQL using the included `docker-compose.yml` this time, though it may be installed by brew etc. The following commands start PostgreSQL as a background process. PostgreSQL automatically starts when host OS reboots, since the restart flag of this container is set as "always".

    ```bash
    $ cd containers/db/
    $ docker-compose up -d
    $ cd ../../
    ```

4. Install ruby

    ```bash
    $ rbenv install
    ```

5. Install gems

    ```bash
    $ gem install bundler
    $ rbenv rehash
    $ bundle install --without development
    ```

6. Install node modules

    ```bash
    $ yarn install
    ```

7. Copy the application configuration files

    ```bash
    $ cp config/database.yml.sample config/database.yml
    $ cp config/environment.yml.sample config/environment.yml
    ```

8. Set up database

    ```bash
    $ bundle exec rake db:setup
    ```

9. Set path to the console

    ```bash
    $ ln -s /path/to/caras-framework/bin/carash /path/to/your/bin/directory/
    ```

### Start carash

Start `carash` anywhere you like.

```
$ cd path/to/where/you/want/to/go
$ carash
*snip*
Welcome to carash.
Now no site is selected.
You must create a new site with following command.
 $ site new Site-1
Or you can select one from existing sites.
 $ site list
 $ site select 1
Enjoy!
carash $
```

The prompt `carash $` will be displayed when carash starts successfully.


Next is to learn [how to use the framework](TUTORIAL.md).

# Install on Kali Linux

## Requirements

The followings are necessary to install to run the framework on Linux. Install them beforehand.

* [rbenv](https://github.com/rbenv/rbenv#installation)
* [ruby-build](https://github.com/rbenv/ruby-build#installation)
* [rbenv-gemset](https://github.com/jf/rbenv-gemset#installation)
* [yarn](https://yarnpkg.com/lang/en/docs/install/#linux-tab)

Though it's not indispensable to the framework, it is recommended to install docker to run PostgreSQL. In the following procedure, docker will be used.

* [docker](https://docs.docker.com/engine/installation/linux/docker-ce/debian/)
* [docker-compose](https://docs.docker.com/compose/install/)

## Install

1. Install dependent packages

    ```bash
    $ apt-get install libssl-dev libreadline-dev zlib1g-dev libxml2-dev libpq-dev
    ```

2. Clone the repository

    Clone Caras-Framework and *TestSuite*.

    ```bash
    $ cd path/to/install
    $ git clone https://github.com/gsx-lab/caras-framework.git
    $ cd caras-framework
    $ git clone https://github.com/gsx-lab/caras-testsuite.git test_suites/default
    ```

3. Start the DBMS

    Start PostgreSQL using the included `docker-compose.yml` this time, though it may be installed from the repository of the distribution. The following commands start PostgreSQL as a background process. PostgreSQL automatically starts when host OS reboots, since the restart flag of this container is set as "always".

    ```bash
    $ cd containers/db/
    $ docker-compose up -d
    $ cd ../../
    ```

4. Install ruby

    ```bash
    $ rbenv install
    ```

5. Install gems

    ```bash
    $ gem install bundler
    $ rbenv rehash
    $ bundle install --without development
    ```

6. Install node modules

    ```bash
    $ yarn install
    ```

7. Copy the application configuration files

    ```bash
    $ cp config/database.yml.sample config/database.yml
    $ cp config/environment.yml.sample config/environment.yml
    ```

8. Set up database

    ```bash
    $ bundle exec rake db:setup
    ```

9. Set path to the console

    ```bash
    $ ln -s /path/to/caras-framework/bin/carash /path/to/your/bin/directory/carash
    ```

### Start carash

Start `carash` anywhere you like

```
$ cd path/to/where/you/want/to/go
$ carash
*snip*
Welcome to carash.
Now no site is selected.
You must create a new site with following command.
 $ site new Site-1
Or you can select one from existing sites.
 $ site list
 $ site select 1
Enjoy!
carash $
```

The prompt `carash $` will be displayed when carash starts successfully

Next is to learn [how to use the framework](TUTORIAL.md).

# Install on docker

## Requirements

docker should be installed to run the framework using docker-compose.

* [Install Docker](https://docs.docker.com/engine/installation/)
* [docker-compose](https://docs.docker.com/compose/install/)

## Install

1. Clone the repository

    Clone Caras-Framework and *TestSuite*.

    ```bash
    $ cd /path/to/install
    $ git clone https://github.com/gsx-lab/caras-framework.git
    $ cd caras-framework
    $ git clone https://github.com/gsx-lab/caras-testsuite.git test_suites/default
    ```

2. Build docker image

    ```bash
    $ docker-compose build
    ```

## Start carash

Execute the following commands in Caras-Framework's root directory, then `carash` will be started.

```
$ docker-compose run --rm app
*snip*
Welcome to carash.
Now no site is selected.
You must create a new site with following command.
 $ site new Site-1
Or you can select one from existing sites.
 $ site list
 $ site select 1
Enjoy!
carash $
```

The prompt `carash $` will be displayed when carash starts successfully.

Next is to learn [how to use the framework](TUTORIAL.md).


## Copy test evidences

All the execution results and log files are saved under caras-app container's `/caras-app/result`. To copy these files to the host, executed the following commands while the container is running.


```bash
$ docker ps --format "{{.Names}}" -f "ancestor=caras-app"
carasframework_app_run_1
$ docker cp carasframework_app_run_1:/caras-app/result ./
```

## Shut down db

If the framework is started this way, `db` continues to run even after `carash` is terminated. Execute the following command to terminate `db`.

```bash
$ docker-compose down
```
