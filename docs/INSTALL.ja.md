# Caras-Framework のインストール方法

[macOS にインストール](#macos-にインストール)

[Kali Linux にインストール](#kali-linux-にインストール)

[docker にインストール](#docker-にインストール)


# macOS にインストール

## システム要件

macOS にインストールする場合は, Xcode と HomeBrew が必要です.

* [Xcode](https://itunes.apple.com/app/xcode/id497799835)
* [HomeBrew](https://brew.sh/)

また, 必須ではありませんが, PostgreSQL を利用するために docker もインストールしておくことをお薦めします. 以降の手順においても docker を使用します.

* [Docker for Mac](https://www.docker.com/docker-mac)

## インストール

1. 依存パッケージをインストール

    ```bash
    $ brew install rbenv rbenv-gemset libxml2 readline postgresql libmagic yarn nmap
    $ brew link --force libxml2
    ```

    rbenv を有効化するため `.bash-profile` に設定を追記します.

    ```bash
    $ echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bash_profile
    $ echo 'eval "$(rbenv init -)"' >> ~/.bash_profile
    ```

2. リポジトリを clone

    Caras-Framework と *TestSuite* を clone します.

    ```bash
    $ cd path/to/install
    $ git clone https://github.com/gsx-lab/caras-framework.git
    $ cd caras-framework
    $ git clone https://github.com/gsx-lab/caras-testsuite.git test_suites/default
    ```

3. DBMS を起動

    brew などでもインストール可能ですが, ここでは同梱の `docker-compose.yml` を使用します. 下記のコマンドは PostgreSQL をバックグラウンドで実行するコマンドです. このコンテナの restart フラグには "always" がセットされているので, ホスト OS の再起動時も自動的に PostgreSQL が起動するようになります.

    ```bash
    $ cd containers/db/
    $ docker-compose up -d
    $ cd ../../
    ```

4. ruby をインストール

    ```bash
    $ rbenv install
    ```

5. gem をインストール

    ```bash
    $ gem install bundler
    $ rbenv rehash
    $ bundle install --without development
    ```

6. node module をインストール

    ```bash
    $ yarn install
    ```

7. アプリケーション設定ファイルをコピー

    ```bash
    $ cp config/database.yml.sample config/database.yml
    $ cp config/environment.yml.sample config/environment.yml
    ```

8. データベースをセットアップ

    ```bash
    $ bundle exec rake db:setup
    ```

9. コンソールへのパスを通す

    ```bash
    $ ln -s /path/to/caras-framework/bin/carash /path/to/your/bin/directory/
    ```

## carash を起動

お好きな場所で `carash` を起動してください.

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

`carash $` というプロンプトが表示されれば起動に成功です.

続いて, [使い方](TUTORIAL.ja.md)を学びましょう.


# Kali Linux にインストール

## システム要件

Linux でこのフレームワークを実行するためには以下のパッケージが必要です. リンクに従ってあらかじめインストールしておきましょう.

* [rbenv](https://github.com/rbenv/rbenv#installation)
* [ruby-build](https://github.com/rbenv/ruby-build#installation)
* [rbenv-gemset](https://github.com/jf/rbenv-gemset#installation)
* [yarn](https://yarnpkg.com/lang/en/docs/install/#linux-tab)

Docker は必須ではありませんが, PostgreSQL を稼働させるのにおすすめです. 続く手順においても Docker を使用します.

* [docker](https://docs.docker.com/engine/installation/linux/docker-ce/debian/)
* [docker-compose](https://docs.docker.com/compose/install/)

## インストール

1. 依存パッケージをインストール

    ```bash
    $ apt-get install libssl-dev libreadline-dev zlib1g-dev libxml2-dev libpq-dev
    ```

2. リポジトリを clone

    Caras-Framework と *TestSuite* をcloneします.

    ```bash
    $ cd path/to/install
    $ git clone https://github.com/gsx-lab/caras-framework.git
    $ cd caras-framework
    $ git clone https://github.com/gsx-lab/caras-testsuite.git test_suites/default
    ```

3. DBMS を起動

    ディストリビューションのリポジトリからでもインストール可能ですが, ここでは同梱の `docker-compose.yml` を使用します. 下記のコマンドは PostgreSQL をバックグラウンドで実行するコマンドです. このコンテナの restart フラグには "always" がセットされているので, ホスト OS の再起動時も自動的に PostgreSQL が起動するようになります.

    ```bash
    $ cd containers/db/
    $ docker-compose up -d
    $ cd ../../
    ```

4. ruby をインストール

    ```bash
    $ rbenv install
    ```

5. gem をインストール

    ```bash
    $ gem install bundler
    $ rbenv rehash
    $ bundle install --without development
    ```

6. node module をインストール

    ```bash
    $ yarn install
    ```

7. アプリケーション設定ファイルをコピー

    ```bash
    $ cp config/database.yml.sample config/database.yml
    $ cp config/environment.yml.sample config/environment.yml
    ```

8. データベースをセットアップ

    ```bash
    $ bundle exec rake db:setup
    ```

9. コンソールへのパスを通す

    ```bash
    $ ln -s /path/to/caras-framework/bin/carash /path/to/your/bin/directory/carash
    ```

## carash を起動

お好きな場所で `carash` を起動してください.

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

`carash $` というプロンプトが表示されれば起動に成功です.

続いて, [使い方](TUTORIAL.ja.md)を学びましょう.

# docker にインストール

## システム要件

docker-compose で使用するには, docker が必要です.

* [Install Docker](https://docs.docker.com/engine/installation/)
* [docker-compose](https://docs.docker.com/compose/install/)

## インストール

1. リポジトリをクローン

    Caras-Framework と *TestSuite* を clone します.

    ```bash
    $ cd /path/to/install
    $ git clone https://github.com/gsx-lab/caras-framework.git
    $ cd caras-framework
    $ git clone https://github.com/gsx-lab/caras-testsuite.git test_suites/default
    ```

2. Docker image を Pull する

    ```bash
    $ docker pull gsxlab/caras-framework
    ```

## carash を起動

Caras-Framework のルートディレクトリで次のコマンドを実行してください. `carash` が起動します.

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

`carash $` というプロンプトが表示されれば起動に成功です.

続いて, [使い方](TUTORIAL.ja.md)を学びましょう.


## 診断証跡のコピー方法

全ての実行結果とログファイルは caras-app コンテナの`/caras-app/result`ディレクトリに保存されています. これらをホスト側にコピーするためには, コンテナの起動中に次のコマンドを実行してください.

```bash
$ docker ps --format "{{.Names}}" -f "ancestor=caras-app"
carasframework_app_run_1
$ docker cp carasframework_app_run_1:/caras-app/result ./
```

## DBMS のシャットダウン方法

この方法でフレームワークを起動した場合, `carash` の終了後も `db` コンテナが自動的に終了することはありません. `db` コンテナを終了するには次のコマンドを実行してください.

```bash
$ docker-compose down
```
