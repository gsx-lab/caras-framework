# チュートリアル

`carash` コンソールを使って脆弱性診断を行います.

## 概要

`carash` を用いた脆弱性診断は, 次のフローで行います.

1. [`carash`を起動する](#carash-を起動)
2. [`site new` で新しいsiteを作成するか, `site select` で既存サイトを選択](#site-new)
3. [`target add` で対象ホストを追加](#target-add)
4. [`testcase run` を用いて*TestCase*を単体で実行](#testcase-run)
5. [`attack` で, ツリー構造の *TestSuite* を自動実行](#attack)
6. [診断が完了したら `report create` でレポート作成](#report-create)

`help` コマンドで実行可能なコマンドの一覧と簡単な説明を確認できます.

いくつかのコマンドはサブコマンドを持っています. あるコマンドに続いて `help` を叩く(例えば `site help`)と, さらに help を見ることができます. 覚えておきましょう.

## carash を起動

Caras-Framework に限らず, 脆弱性診断のためのツールには特権を必要とするものがあります. [インストール](INSTALL.ja.md)したサンプル *TestSuite* にも, 特権が必要な *TestCase* が含まれています.

```bash
$ sudo carash
```

なお, docker-compose を使用している場合は, `sudo` をつける必要はありません.

## site new

`carash` では, 複数の *target* IP アドレスで *site* を構成します. 診断は *site* に登録された *target* IP アドレスを対象に行われます.

ここでは, "sample_site" という新しい *site* を作成します.

```
carash # site new sample_site
create a new site named sample_site
carash [sample_site] #
```

プロンプトが `carash [sample_site]` に変わりました. これは現在選択されている *site* が "sample_site" である, ということを示しています.

## target add

*site* に *target* ホストを追加します.

```
carash [sample_site] # target add 127.0.0.1
Added ip address : 127.0.0.1
carash [sample_site] #
```

これで `127.0.0.1` が *target* ホストとして *site* に追加されました. 現在登録されているホストを確認したい場合は `target list`, ホストを削除したい場合は `target delete <number> | <IP address>` を実行しましょう. `<number>` は `target list` コマンドで確認できる番号です.

```
carash [sample_site] # target list
 List of Host

 1  127.0.0.1

carash [sample_site] # target delete 1
Really want to delete target 127.0.0.1? [Y/n] > Y
Deleted target 127.0.0.1 successfully
carash [sample_site] #
```

次の手順に進む前に, もう一度 `target add 127.0.0.1` で対象ホストを追加しておきましょう.

## testcase run

Caras-Framework は複数の *TestCase* を自動実行するためのものですが, 一つの *TestCase* だけを実行したい場合もあります. サンプルの *TestSuite* には `ImportNmapResult` という自動実行されない *TestCase* があります.

プロの脆弱性テスタはポートスキャンを行う際, ネットワークの状態や対象ホストの応答に応じて様々なオプションを使い分けるものです.

`ImportNmapResult` を使う前に `nmap` を実行し, その結果を xml か text 形式で `$(pwd)/nmap/` というディレクトリに保存しておきます.

オプションなしの `testcase run` で, 実行可能な *TestCase* の一覧が表示されます.

```
carash [sample_site] # testcase run
Run test case individually.
Select test case number to run or "x" to exit
                  List of Test case

 1  TestSuites::Default::Icmp::Ping
 2  TestSuites::Default::Tcp::SslConnect
 3  TestSuites::Default::Tcp::Http::DetectHttpService
 4  TestSuites::Default::Tcp::Http::BannerGrabber
 5  TestSuites::Default::ImportNmapResult
 6  TestSuites::Default::Tcp::SynScan

Which do you want to run? [1 - 6]
```

または, `testcase run TestSuites::Default::ImportNmapResult` といったオプションをつけると, 直接次のダイアログが表示されます.

上記の例では `ImportNmapResult` の番号 `5` を応えます.

続いて *target* ホストを選択します.

```
Select target host to test or "x" to exit
   List of Host

 1  127.0.0.1

Which do you want to test? [1]
```

この問い合わせに応えると `ImportNmapResult` の処理が始まります.


```
Which do you want to test? [1] 1
TestSuites::Default::ImportNmapResult instantiated
TestSuites::Default::ImportNmapResult start
TestSuites::Default::ImportNmapResult on 127.0.0.1 start (waiting:0 running:1/30)
Ctrl+c to cancel.
Specify nmap result directory (/Users/gsx/nmap) >
```

ディレクトリを与えずに Enter を入力するとデフォルトのディレクトリが選択されます. 表示されているパスに nmap の結果が保存されていることを確認して Enter を押してください.

すると, nmap のログをパースした結果が表示されます.

```
+------+-------+-------+-------------+------------------------------------------------------------------+
|                                               tcp ports                                               |
+------+-------+-------+-------------+------------------------------------------------------------------+
| No.  | proto | state | service     | version                                                          |
+------+-------+-------+-------------+------------------------------------------------------------------+
| 21   | tcp   | open  | ftp         | vsftpd 2.3.4                                                     |
| 22   | tcp   | open  | ssh         | OpenSSH 4.7p1 Debian 8ubuntu1 (protocol 2.0)                     |
| 23   | tcp   | open  | telnet      | Linux telnetd                                                    |
| 25   | tcp   | open  | smtp        | Postfix smtpd                                                    |
*snip*
Import these result? [Y/n] >
```

期待した通りであれば `Y` を入力して完了です.

```
Import these result? [Y/n] > Y
TestSuites::Default::ImportNmapResult end
carash [sample_site] #
```

現在のホストの状況を知りたかったら `dump` コマンドが便利です. このコマンドを使うことで *target* ホストのポートが表示されます.

```
carash [sample_site] # dump
ip : 127.0.0.1
+------+-------+-----+-------+---------+--------------+------------------------------------------------------------------+
|                                                       tcp ports                                                        |
+------+-------+-----+-------+---------+--------------+------------------------------------------------------------------+
| no   | state | ssl | plain | service | nmap_service | nmap_version                                                     |
+------+-------+-----+-------+---------+--------------+------------------------------------------------------------------+
| 21   | open  |     |       |         | ftp          | vsftpd 2.3.4                                                     |
| 22   | open  |     |       |         | ssh          | OpenSSH 4.7p1 Debian 8ubuntu1 (protocol 2.0)                     |
| 23   | open  |     |       |         | telnet       | Linux telnetd                                                    |
| 25   | open  |     |       |         | smtp         | Postfix smtpd                                                    |
*snip*
carash [sample_site] #
```

## attack

オープンポートの登録ができたら `attack` の準備が完了です. 単に `attack` と打ち込んでください.

```
carash [sample_site] # attack
Start tester for 127.0.0.1
carash [sample_site] # Done tests for 127.0.0.1
Done all tests
```

しばらく待つと, `Done all tests` と表示されます. これでテストは完了です.

テストの実行に長い時間がかかっており, 状況を知りたい場合は `status` を叩くと良いでしょう.

```
carash [sample_site] # status
Tester:127.0.0.1@sample_site => running: [ 2 > 1 > 1 ]
 root
 |--fin TestSuites::Default::Icmp::Ping
 `--run TestSuites::Default::Tcp::SslConnect
    `--TestSuites::Default::Tcp::Http::DetectHttpService
       `--TestSuites::Default::Tcp::Http::BannerGrabber
Queued  testers : 6
Running testers : 6/30
Waiting testers : 0
All threads     : 19
carash [sample_site] #
```

もっと詳細に状況を知りたい場合は `toggle` コマンドが有効です. このコマンドを一度叩くと *TestCase* が生成する全てのログがリアルタイムにコンソールへ表示されるようになります.

```
carash [sample_site] # toggle
Showing sub thread message : true
carash [sample_site] #
Tester:127.0.0.1@sample_site start running
TestSuites::Default::Icmp::Ping for 127.0.0.1 instantiated
TestSuites::Default::Icmp::Ping on 127.0.0.1 start (waiting:0 running:1/30)
TestSuites::Default::Tcp::SslConnect for 127.0.0.1 instantiated
TestSuites::Default::Tcp::SslConnect on 127.0.0.1:22/tcp start (waiting:0 running:18/30)
*snip*
```

ログメッセージの表示を止めたい場合は, もう一度 `toggle` コマンドを実行してください.

途中でテストを止めたくなったら `stop` コマンドを使ってください. これでテストを中断できますが resume 機能はありません.

## report create

全てのテストが完了したら, `report create` コマンドでレポートを作成しましょう.

```
carash [sample_site] # report create
Report is created in /User/gsx/result/sites/sample_site/report_20170801-010203.html
carash [sample_site] #
```

表示されたパスに html ファイルが出力されるので, お好きなブラウザで閲覧してください. macOS 上で実行している場合は自動的にブラウザが起動します.

`$(pwd)/result` というディレクトリが作成されていることに気づきましたか? このディレクトリにはログファイルや *TestCase* の実行結果が保存されています.

# まとめ

このチュートリアルが参考になれば幸いです. `carash` には他にも様々なコマンドがあります. help を見たり, 実際に実行したりしましょう. `attack` コマンドと `testcase run` コマンド以外は安全です.

これでチュートリアルは終わりです.

続いて, [*TestSuite* を開発](DEVELOP_TEST_SUITES.ja.md)しましょう.
