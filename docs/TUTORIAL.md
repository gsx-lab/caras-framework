# Tutorial

In order to run vulnerability scanning, use `carash` console as explained below.

## Overview

vulnerability scanning with use of `carash` take the following procedure.

1. [start `carash`](#boot-carash)
2. [`site new` to create a new site or `site select` to select the existing sites](#site-new)
3. [`target add` to add a target host](#target-add)
4. [`testcase run` to execute the single *TestCase*](#testcase-run)
5. [`attack` to automatically execute tree-shaped *TestSuite*](#attack)
6. [`report create` to create report after the completion of the test](#report-create)

The command `help` shows the list of available commands and their brief explanations.

Some commands have subcommands. Press `help` after a command(`site help` for instance), the list and the brief explanations of its subcommands are shown. Bear it in mind.

## boot carash

You may know, some tools for vulnerability scanning, not limited to Caras-Framework, need the root privilege. An [Installed](INSTALL.md) sample *TestSuite* has *TestCase*s that need the privilege as well.


```bash
$ sudo carash
```

When using docker-compose, you won't need `sudo`.


## site new

In `carash`, *site* is a group that consists of *target* IP addresses. Scan is executed for the *target*s under the management of *site*.

Below is an example to create *site* named "sample_site".

```
carash # site new sample_site
create a new site named sample_site
carash [sample_site] #
```

The prompt changes to `carash [sample_site]`, which suggests that "sample_site" is the *site* currently selected.

## target add

Add a target host to *site*.

```
carash [sample_site] # target add 127.0.0.1
Added ip address : 127.0.0.1
carash [sample_site] #
```

`127.0.0.1` is added as a *target* host to *site*. `target list` lists the hosts that the *site* contains. `target delete <number> | <IP address>` deletes the host specified by `<number>` or `<IP address>`. `<number>` may be confirmed by `target list` command.

```
carash [sample_site] # target list
 List of Host

 1  127.0.0.1

carash [sample_site] # target delete 1
Really want to delete target 127.0.0.1? [Y/n] > Y
Deleted target 127.0.0.1 successfully
carash [sample_site] #
```

Before proceeding, execute `target add 127.0.0.1` once again.

## testcase run

Although Caras-Framework is to execute multiple *TestCase*s consecutively, you might want to run a single *TestCase* manually. The sample *TestSuite* contains `ImportNmapResult` that is useful for that.

Skilled penetration testers wisely choose command options for port scanning, depending on network conditions, responses upon attacks, and so forth. 

Before using `ImportNmapResult`, run `nmap` and save its result in the form of either xml or text under the directory `$(pwd)/nmap/`

Hit `testcase run` with no option shows the list of executable *TestCase*s.

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

A command with option like `testcase run TestSuites::Default::ImportNmapResult` immediately shows the next dialogue.

In the example above, select `5` to run `ImportNmapResult`.

Next is to select the *target* host.

```
Select target host to test or "x" to exit
   List of Host

 1  127.0.0.1

Which do you want to test? [1]
```

Provide a reply, `ImportNmapResult` will start.

```
Which do you want to test? [1] 1
TestSuites::Default::ImportNmapResult instantiated
TestSuites::Default::ImportNmapResult start
TestSuites::Default::ImportNmapResult on 127.0.0.1 start (waiting:0 running:1/30)
Ctrl+c to cancel.
Specify nmap result directory (/Users/gsx/nmap) >
```

Press Enter with no directory given, then the default path will be selected. Make sure that the nmap logs are stored in the displayed directory, and press Enter.

Then, the parsed nmap log will be displayed.

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

If expected result is shown, press `Y` to exit.

```
Import these result? [Y/n] > Y
TestSuites::Default::ImportNmapResult end
carash [sample_site] #
```

`dump` command may be useful to know the status of the current host. With this command executed, the ports of the *target* host are listed.

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

If open ports are registered, then `attack` is prepared. Just perform `attack` command.


```
carash [sample_site] # attack
Start tester for 127.0.0.1
carash [sample_site] # Done tests for 127.0.0.1
Done all tests
```


Wait for a while, then `Done all tests` will appear as shown above. This concludes a test.

In case the execution takes a long time, `status` command may be used to know the progress status of the test.

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

To know the status more in detail, `toggle` command may be useful. Once this command is performed, all the log that *TestCase* generates will be displayed in the console in real time.

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

To stop the log from being shown, execute `toggle` again.


To break off the test, use `stop` command. Once this command is executed, the test is terminated with no way to resume it.

## report create


When all the tests are completed, execute `report create` command to create a report.


```
carash [sample_site] # report create
Report is created in /User/gsx/result/sites/sample_site/report_20170801-010203.html
carash [sample_site] #
```

An html file will be generated in the displayed path. Check the file using the browser of your choice. If the framework runs on macOS, the browser will be automatically launched.


Notice that a directory named `$(pwd)/result` is created. This directory contains logfile and the outputs of *TestCase*.

# Conclusion

Hope you'll find this tutorial helpful. `carash` has many other commands. Get familiar with them by referring to help or trying them out. Only `attack` and `testcase run` require safety precautions.

This is the end of the tutorial. The next step is to [develop *TestSuite*s](DEVELOP_TEST_SUITES.md)
