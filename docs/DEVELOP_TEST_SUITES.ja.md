# *TestSuite* の開発

*TestSuite* の開発は, 次の手順で行います.

1. [開発環境を準備する](#開発環境の準備)
2. [*TestSuite* を設置するディレクトリを作成する](#testsuite-用ディレクトリの作成)
3. [*TestCase* のテンプレートを生成する](#testcase-テンプレートの生成)
4. [テンプレートを元に Awesome な *TestCase* を実装する](#テンプレートを元に-Awesome-な-testcase-を実装)
5. [実装した *TestCase* を実行する](#実装した-testcase-を実行)

## 開発環境の準備

Caras-Framework にはビルトインの開発モードがあります.

まず, 開発を便利にする gem をインストールします.

```bash
$ cd caras-framework/
$ bundle config --delete without
$ bundle install
```

インストール後は, `config/environment.yml` は次のようになっているはずです.

```yaml
environment: production
db_env: production
# db_env: development
# db_env: test
test_case_thread_limit: 30
log_shift_age: daily  # Log rotation
log_level: :info      # :debug, :info, :warn, :error, :fatal
```

これを編集して開発モードに切り替えます.

`environment:` と `db_env:` を `development` に変更し, `log_level:` を `:debug` に変更します.

```yaml
environment: development
db_env: development
# db_env: development
# db_env: test
test_case_thread_limit: 30
log_shift_age: daily  # Log rotation
log_level: :debug     # :debug, :info, :warn, :error, :fatal
```

続いて, development 用の DB をセットアップします.

```bash
$ bundle exec rake db:setup
```

これで *TestSuite* の開発準備は完了です.

## *TestSuite* 用ディレクトリの作成

*TestSuite* には専用のディレクトリが必要です.

`path/to/caras-framework/test_suites/` 配下に新しいディレクトリを作成します.

```bash
$ cd caras-framework/test_suites
$ mkdir my_test_suite
```

## *TestCase* テンプレートの生成

もう一つのターミナルを起動して, お好きな場所で `carash` を起動します.

```bash
$ cd path/to/where/you/want/to/go
$ carash
*snip*
carash $
```

`carash` が起動したら, 先ほど作ったディレクトリが認識されているか確認しましょう. `testsuite list` コマンドを叩きます.

```
carash $ testsuite list
+---+----+---------------+-------+------------------------------------------------+--------+-----------+
|   | No | Dir           | Tests | RemoteUrl                                      | Branch | Describe  |
+---+----+---------------+-------+------------------------------------------------+--------+-----------+
| ✔ | 1  | default       | 6     | https://github.com/gsx-lab/caras-testsuite.git | master |           |
|   | 2  | my_test_suite | 0     |                                                |        |           |
+---+----+---------------+-------+------------------------------------------------+--------+-----------+
carash $
```

`my_test_suite` が表示されていれば新しいディレクトリは正常に認識されています.

`carash` は起動時に `test_suites/default` に保存されている *TestSuite* を選択します. もし自分の *TestSuite* をデフォルトにしたい場合は自分のディレクトリを `default` に変更してください.

ここでは `my_test_suite` のまま説明を続けます.

新しい *TestSuite* を選択するには `testsuite select` コマンドに数値を与えます. 引数は `testsuite list` コマンドで表示された `No` です.

```
carash $ testsuite select 2
unloaded TestSuites::Default::Icmp::Ping
unloaded TestSuites::Default::Icmp
unloaded TestSuites::Default::ImportNmapResult
unloaded TestSuites::Default::Tcp::Http::BannerGrabber
unloaded TestSuites::Default::Tcp::Http::DetectHttpService
unloaded TestSuites::Default::Tcp::Http
unloaded TestSuites::Default::Tcp::SslConnect
unloaded TestSuites::Default::Tcp::SynScan
unloaded TestSuites::Default::Tcp
unloaded TestSuites::Default
unloaded TestSuites
+---+----+---------------+-------+-----------+--------+----------+
|   | No | Dir           | Tests | RemoteUrl | Branch | Describe |
+---+----+---------------+-------+-----------+--------+----------+
| ✔ | 2  | my_test_suite | 0     |           |        |          |
+---+----+---------------+-------+-----------+--------+----------+
carash #
```

現在ロードされている *TestSuite* をアンロードし, `my_test_suite` がロードされます. *TestSuite* は複数の *TestCase* で構成されるということを思い出してください. 新しい *TestSuite* のために *TestCase* を追加する必要があります.

新しい *TestCase* のためにテンプレートを生成しましょう.

```
carash $ testcase new my/great_test.rb
new test case is generated in /path/to/caras-framework/test_suites/my_test_suite/my/great_test.rb
carash $
```

新しい *TestCase* を作成したり既存の *TestCase* を修正した場合は, `testsuite reload` コマンドで *TestSuite* をリロードすることができます.

```
carash # testsuite reload
loaded TestSuites::MyTestSuite::My::GreatTest
carash #
```

## テンプレートを元に Awesome な *TestCase* を実装

`testcase new` コマンドは以下のようなテンプレートを生成します.

```ruby
#
# My::GreatTest
#
class GreatTest < TestCaseTemplate
  @description = 'sample description of test GreatTest'

  # Specify parent test case module name like 'My::GreatTest'.
  # Other option:
  #   @requires = nil          # has no parent test case, starts first.
  #   @requires = 'Individual' # does not implement test suite tree.
  @requires = nil

  # Specify test target protocol
  @protocol = 'sample protocol'

  # Your name
  @author = ''

  # If this test case runs for one host, define 'attack' method, and
  # do NOT define 'target_ports' nor 'attack_on_port' methods.
  def attack
    # write your great test off!
  end

  # If this test case runs for every port, implement below methods
  # 'target_ports' and 'attack_on_port', and *DELETE 'attack' method*.

  # target_ports extracts attack target ports
  # @return [ActiveRecord::Relation, Array<Port>]
  # def target_ports
  #   # define extract target ports.
  #   @host.tcp.service('http')
  # end

  # attack_on_port runs for each port.
  # @param [Port] port target port
  # def attack_on_port(port)
  #   # write your great test off!
  # end
end
```

4つのクラスインスタンス変数 `@description`, `@requires`, `@protocol`, `@author` と, ひとつのインスタンスメソッド `attack` がすでに実装されています. コメントアウトされた `target_ports` メソッドと `attack_on_port` メソッドも気になりますね.

### クラスインスタンス変数

#### @description, @protocol, @author

これらの変数は, この`TestCase`そのものを説明する為のものです.

```ruby
  @description = 'This is a great test'
  @protocol = 'TCP/HTTP'
  @author = 'John Doe'
```

`testcase info` コマンドを使う事で, これらの変数をコンソールに表示します. *TestCase* の詳細な情報をここに記述することで, この *TestCase* を利用しやすくします.

```
carash $ testsuite reload
carash $ testcase info
TestSuites::MyTestSuite::My::GreatTest
 description  This is a great test
 protocol     TCP/HTTP
 requires
 dangles      tree
 author       John Doe
carash $
```

#### @requires

この変数は実行前の状況を指示します. 指定された値はこの *TestCase* が実行される前に終了しているべきクラスを指示します. *TestCase* には階層構造の依存関係を持たせることができ, 実行順序はこの変数によって制御されます. 指示の仕方には3つの方法があります.

  * `nil`

    この *TestCase* は最初に(他の *TestCase* の終了を待たずに)実行されます.

  * `'Any::Other::Test::Case'`

    この *TestCase* は `Any::Other::Test::Case` の終了後に実行されます. ここで指定すべきクラス名は, `testcase new` コマンドで生成されたコードの2行目に記述されています. 先の例であれば `My::GreatTest` です. この名称は, `my_test_suite` ディレクトリから rb ファイルへの相対パスと一致します. すなわち, `caras-framework/test_suites_my_test_suite/any/other/test/case.rb` の場合は `Any::Other::Test::Case` です.

    もし, 存在しないクラス名を指定した場合は `orphan` *TestCase* であると認識されて, 自動的には実行されません.

  * `'Individual'`

    この *TestCase* はスタンドアロンです. 他の *TestCase* には依存せず, また `attack` コマンドでも実行されません. `testcase run` コマンドでのみ実行可能です.


#### `attack`

`attack` メソッド (コンソールの `attack` コマンドと混同しないように気をつけて下さい) は単一のホストを対象として実行されます. 複数の *target* ホストが存在する場合, それぞれのホストに対応した *TestCase* インスタンスが生成され, それぞれの `attack` メソッドが呼びだされます.

#### `target_ports`

ポート毎に *TestCase* を実行したい場合は, `target_ports` と `attack_on_port` メソッドを定義し, `attack` メソッドを削除してください.

`target_ports` メソッドは対象とする *Port* レコードを抽出するメソッドです. `ActiveRecord::Relation` インスタンスか, *Port* モデルの配列を返却するように実装してください.

#### `attack_on_port`

`attack` メソッドはホストごとに実行されるメソッドでしたが, `attack_on_port` メソッドはポートごとに実行されるメソッドです. `attack_on_port` は `target_ports` によって抽出されたすべての *Port* モデルごとに実行されます. 複数のポートが抽出された場合は, そのポートの数だけ並列に実行されます.

ポートに対するテストを定義したい場合は, `target_ports` メソッドと `attack_on_port` メソッドを定義し, `attack` メソッドを削除して下さい.

### その他のインスタンス変数

そのほかにもインスタンス変数が多数あります. 詳しくは `app/test_case_template.rb` を参照してください.

| 変数 | 説明 |
|---|---|
| @data_dir | その *TestCase* に割り当てられたディレクトリを示す *Pathname* のインスタンス. このディレクトリは初期状態では存在しないので, 必要に応じて作成して下さい. |
| @path_to | `carash` システムに関連するファイルやディレクトリへのパス(*Pathname*)をまとめた *Array* |
| @host | 対象ホストを示す *Host* のモデル |
| @site | 対象ホストが属する *Site* のモデル |
| @ip | 診断対象ホストのIPアドレスを示す *String* |
| @console | ログメッセージの出力とユーザからの入力を受けつける *Console* のインスタンス |
| @site_mutex | *Site* 単位で使用される同期処理用のMutex |
| @mutex | 大将ホスト単位の同期処理用の Mutex. `attack_on_port` メソッドは *TestCase* インスタンスによって生成された多数の *Thread* から実行されます. `attack_on_port` メソッドの実装に於いて, 同期処理が必要な場合は `@mutex` を使用してください. |

### 実装済みの method

テンプレートに明記されていないメソッドも複数あります. これらは multi-thread で実行される *TestCase* から *DB* や *Thread*, *Process* の整合性を守るために定義されています. *DB* 更新や外部コマンド呼び出しにはなるべくこれらのメソッドを利用してください.

  * `register_banner` の呼び出しサンプル

    先に述べた通り *TestCase* は multi-thread で実行されます. そのため, 同じレコードへの更新ジョブが発生することを考慮しなければなりません. `register_banner` はデータの整合性を保つために同期処理を行います.

    ```ruby
      register_banner(port, 'Server: Apache/2.2.0')
    ```

  * `register_vulnerability` の呼び出しサンプル

    こちらも同様に同期処理されます.

    ```ruby
      register_vulnerability(
        evidence,
        name: 'The name of the vulnerability',
        severity: :info, # severity. Choose one from :info, :low, :middle, :high, :critical
        description: 'Detailed description of the vulnerability'
      )
    ```

  * `create_evidence` の呼び出しサンプル
    `create_evidence` は *TestCase* ごとに定義された初期値が設定された証跡を作成します.

    ```ruby
      evidence = create_evidence(
        @host,
        payload: 'The content of the test, such as used commands or sent data',
        data: 'The test results to prove the existence of vulnerability such as response data'
      )
    ```

  * `command` の呼び出しサンプル

    このメソッドは外部コマンドを実行します. DB へのアクセスはありません.

    `carash`では, Thread だけではなく子プロセスも管理するために特別なメソッドを用意しました.

    呼び出し例を見てみましょう.

    ```ruby
      result = command("ping -c 4 #{@ip}", 'ping.log', ttl: 10)
      result[:out]     # => [String, nil]  : stdout(nil if timed out)
      result[:err]     # => [String, nil]  : stderr(nil if timed out)
      result[:status]  # => [Integer, nil] : exit status(nil if timed out)
      result[:timeout] # => [Boolean]      : timed out or not
    ```

    この様に呼び出すと, `command` メソッドは第一引数のコマンドを実行し, その stdout と stderr を *TestCase* のために用意されたディレクトリ直下の`ping.log` というファイルに出力します. 実行が完了したら, コマンドの stdout, stderr, status を含む Hash オブジェクトを返却します. `ttl` で指示された時間内にコマンドが完了しなかった場合は, そのプロセスを kill し, `timeout` に `true` をセットします. その場合は `err` と `out` は返却されません. `append` パラメータはログファイルへの追記モードを指示します. デフォルトでは `true` です.

### 実装例

より実践的なサンプルの実装を見ていきましょう. http のポートにアクセスして, Server ヘッダを取得する 'http banner grabber' の作り方です. http のポートごとに実行したいので `target_ports` メソッドと `attack＿on＿port` メソッドを実装します.

まずは `target_ports` の実装です. nmap の service detection の結果が 'http' であるポートを抽出します. 

```ruby
  def target_ports
    # extract http ports
    @host.tcp.nmap_service('http')
  end
```

続いて `attack_on_port` の実装です. 少し長いですが, 難しくはありません.

```ruby
  def attack_on_port(port)
    # Instantiate http object
    http = Net::HTTP.new(@ip, port.no)

    # Use ssl if port no is 443
    if port.no == 443
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end

    # Send HEAD request and receive response
    response = http.head('/')
    @console.info self, "#{@ip}:#{port.no} HEAD requested"

    return unless response['Server'] # Could not find Server header

    # Server header exists
    @console.warn self, "#{@ip}:#{port.no} Server header found : #{response['Server']}"

    # Create a new evidence
    evidence = create_evidence(port, payload: 'HEAD', data: response['Server'])

    # Create a new vulnerability which refers a evidence
    register_vulnerability(
      evidence,
      name: 'Responds Server header',
      severity: :critical,
      description: 'Responding Server header may or may not cause critical unknown issue.'
    )
  end
```

`@console` を使って積極的に debug メッセージを表示するようにしましょう. コンソールやログファイルの情報量を増やす事を強く推奨します. `debug` メソッドだけではなく `info` や `warn`, `error` なども使うと, 人生がより豊かになることでしょう.

## 実装した *TestCase* を実行

あらかじめ対象ホストをセットアップしポートスキャンを完了しておきます. [チュートリアル](TUTORIAL.ja.md)で行ったのと同じ様にポートスキャンの結果をロードしておきます. 今回の *TestCase* では, `nmap_service` フィールドを参照するので, nmap でサービススキャンを行なっておくと良いでしょう.

### testcase run

nmap レポートをロードしたら, `testcase run` コマンドで `GreatTest` を実行しましょう.

```
carash [sample_site] # testcase run
Select test case number to run or "x" to exit
             List of Test case

 1  TestSuites::MyTestSuite::My::GreatTest

Which do you want to run? [1] 1
Select target host to test or "x" to exit
   List of Host

 1  127.0.0.1

Which do you want to test? [1] 1
Select target port number
 or 0 to leave it to test case's choice. [0 - 65535] 0
TestSuites::MyTestSuite::My::GreatTest instantiated
TestSuites::MyTestSuite::My::GreatTest start
TestSuites::MyTestSuite::My::GreatTest on 127.0.0.1:8180 start (waiting:0 running:3/30)
TestSuites::MyTestSuite::My::GreatTest on 127.0.0.1:80 start (waiting:0 running:3/30)
127.0.0.1:8180 HEAD requested
127.0.0.1:8180 Server header found : Apache-Coyote/1.1
127.0.0.1:80 HEAD requested
127.0.0.1:80 Server header found : Apache/2.2.8 (Ubuntu) DAV/2 mod_ssl/2.2.8 OpenSSL/0.9.8g
TestSuites::MyTestSuite::My::GreatTest on 127.0.0.1:443 start (waiting:0 running:3/30)
TestSuites::MyTestSuite::My::GreatTest on 127.0.0.1:8180 end (waiting:0 running:2/30)
TestSuites::MyTestSuite::My::GreatTest on 127.0.0.1:80 end (waiting:0 running:1/30)
127.0.0.1:443 Server header found : Apache/2.2.8 (Ubuntu) DAV/2 mod_ssl/2.2.8 OpenSSL/0.9.8g
127.0.0.1:443 HEAD requested
TestSuites::MyTestSuite::My::GreatTest end
carash [sample_site] # TestSuites::MyTestSuite::My::GreatTest on 127.0.0.1:443 end (waiting:0 running:0/30)

carash [sample_site] # report create
Report is created in /path/to/result/sites/sample_site/report_20170801-010203.html
carash [sample_site] #
```

期待した通りに動いたでしょうか? もし問題があったたら `binding.pry` を使ってバグしてください. 問題を見つけ解決したら `testsuite reload` で *TestCase* を読み込みなおし, 改めて `testcase run` コマンドでテストしましょう. うまくいったら `attack` コマンドも試しましょう.

### debug mode で carash を起動

`carash` には debug モードがあります. debug モードでは, `carash` の初期化後, コンソールを起動する前の状態で pry コンソールが立ち上がります. debug モードに入るには環境変数 `DEBUG=1` をセットして `carash` を起動します.

```
$ DEBUG=1 carash
*snip*
[1] pry(main)>
```

この状態で ActiveRecord が DB に接続しているのです, `binding.pry` を使用せずに DB アクセスが可能です.

```
1] pry(main)> Host.first
=> #<Host:0x007f86f05dfda8 id: 1, site_id: 1, ip: "127.0.0.1", test_status: "tested", created_at: 2017-08-01 01:02:03 +0900, updated_at: 2017-08-01 01:02:03 +0900>
[2] pry(main)>
```

このモードを使って DB のメンテナンスを行ったり, *TestCase* で使用する新しい gem を試したりすることができます.

# おわりに

このチュートリアルが参考になれば幸いです. より応用的な内容を知りたい場合はサンプルの *TestSuite* を参照して下さい.

新しい *TestSuite* をつくったら, 私たちに教えていただけると幸いです.
