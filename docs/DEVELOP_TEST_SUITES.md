# Develop *TestSuite*s

Follow the following procedure to develop *TestSuite*s.

1. [Prepare for development](#prepare-for-development)
2. [Create a directory for a *TestSuite*](#create-a-directory-for-a-testsuite)
3. [Generate a *TestCase* template](#generate-a-testcase-template)
4. [Implement awesome *TestCase*s based on template](#implement-awesome-testcases-based-on-template)
5. [Running the implemented *TestCase*](#running-the-implemented-testcase)

## Prepare for development

Caras-Framework has a built-in development mode.

First, install gems to setup development tools.

```bash
$ cd caras-framework/
$ bundle config --delete without
$ bundle install
```

After installation, `config/environment.yml` should look like as follows.

```yaml
environment: production
db_env: production
# db_env: development
# db_env: test
test_case_thread_limit: 30
log_shift_age: daily  # Log rotation
log_level: :info      # :debug, :info, :warn, :error, :fatal
```

Then, edit `config/environment.yml` to switch the setting to development mode.

Modify the values of `environment:` and `db_env:` to `development`, and `log_level:` to `:debug`.


```yaml
environment: development
db_env: development
# db_env: development
# db_env: test
test_case_thread_limit: 30
log_shift_age: daily  # Log rotation
log_level: :debug     # :debug, :info, :warn, :error, :fatal
```

Next, set up DB for development.

```bash
$ bundle exec rake db:setup
```

Now you are ready to write your own *TestSuite*s.


## Create a directory for a *TestSuite*

Each *TestSuite* requires an independent directory.

Create a directory under `path/to/caras-framework/test_suites/`


```bash
$ cd caras-framework/test_suites
$ mkdir my_test_suite
```


## Generate a *TestCase* template

Launch one more terminal, and start `carash` in any directory of your choice.

```bash
$ cd path/to/where/you/want/to/go
$ carash
*snip*
carash $
```

After `carash` is started, make sure that the directory you created is on the list.  Run `testsuite list` command.


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

If `my_test_suite` appears, then the new directory is successfully recognized.

`carash` looks for *TestSuite*s in `test_suites/default` on startup.  If you prefer to call a *TestSuite* 'default', change the name of the directory for this particular *TestSuite* so.

In the following example, we will call the *TestSuite* `my_test_suite`.

Now, `carash` needs to direct itself to a *TestSuite* of interest.  In order to do that, run `testsuite select` command with an integer argument.  The argument appears in the `No` column, which `testsuite list` command shows.


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

As shown in the log, the command above detach the active *TestSuite* and loads a *TestSuite* of interest, which in this example is called `my_test_suite`.  Remember, a *TestSuite* is a container that holds *TestCase*s.  But the newly attached *TestSuite* is now empty.  From now on, you will program the *TestSuite* and add *TestCase*s to it.

Generate a template for the new *TestCase*.  You might want to name it.  Of course, you can add more than one if you wish.


```
carash $ testcase new my/great_test.rb
new test case is generated in /path/to/caras-framework/test_suites/my_test_suite/my/great_test.rb
carash $
```

After adding *TestCase*s and modifying them, run `testsuite reload` to refresh the entire *TestSuite* that holds them.

```
carash # testsuite reload
loaded TestSuites::MyTestSuite::My::GreatTest
carash #
```

## Implement awesome *TestCase*s based on template


`testcase new` command with an argument generates a template whose content should look like the following.


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

The template already has four class instance variables and one method: namely, `@description`, `@requires`, `@protocol`, `@author`, and `attack` method.  Pay special attention to the comments in the template file.

### Instance variables

#### @description, @protocol, @author

Those variables are hopefully self-explanatory.

```ruby
  @description = 'This is a great test'
  @protocol = 'TCP/HTTP'
  @author = 'John Doe'
```

`testcase info` shows the values set to the instance variables.  You might want to add descriptions in detail to make your *TestCase* easy to use.

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

This variable specifies pre-execution context.  In other words, those defined as the values of this variable must be finished prior to its actual *TestCase* execution.  *TestCase*s may form hierarchical dependencies and determine the order of their execution sequence by setting these values.  There are three ways to establish such behavior.


  * `nil`

    This will bring the *TestCase* first (or near first) in the execution sequence.

  * `'Any::Other::Test::Case'`

    This will tell *TestCase* to start after `Any::Other::Test::Case`.  You need to specify the class name shown in the second line in the template.  In this particular example, it is `My::GreatTest`.  The class name with namespace corresponds to the relative path from `my_test_suite` directory to the rb file.  More specifically, `Any::Other::Test::Case` represents `caras-frmaework/test_suites/my_test_suite/any/other/test/case.rb`.
	
    If non-existing or invalid class names are given, they would become `orphan` *TestCase*s, meaning unexecutable.

  * `'Individual'`

    This means that *TestCase*s are stand-alone.  In other words, they do not depend on other *TestCase*s.  They do not run by `attack` command.  They can only run by `testcase run`.


#### `attack`

`attack` method (don't confuse with `attack` command, which is a framework interface) aims at a single *target* host.  That is to say, `attack` method gets called as many times as the number of the *target* hosts.  If you have more than one target host, the same number of TestCase instances will be created and they form one-to-one correspondence.

#### `target_ports`

If you wish to run *TestCase* on every port, implement both `target_ports` and `attack_on_port`, deleting the `attack` method.

`target_ports` method extracts target *Port* record.  Make sure that `target_ports` returns either an ActiveRecord::Relation instance or an Array of *Port* models.

#### `attack_on_port`

`attack_on_port` is port-wise executable whereas `attack` method is host-wise.  `attack_on_port` gets executed on every *Port* model instance, discovered by `target_ports`.  If more than one port is found open, the execution parallelly multiplies itself as many as the number of discovered ports.

Disable `attack` method if you only wish to perform a penetration testing on a single port.


### Other instance variables

There are many additional instance variables.  You may find `app/test_case_template.rb` useful to understand what they do.

| variable | description |
|---|---|
| @data_dir | A *Pathname* instance that corresponds to the directory assigned to the *TestCase*.  The directory does not exist by default, thus you need to create one. |
| @path_to | *Array* of paths (Pathname) to the files and directories that `carash` system has |
| @host | model of *Host* that indicates a target host |
| @site | model of *Site* that holds target hosts |
| @ip | String value that indicates the IP address of the target host |
| @console | instance of *Console* that accepts log messages and user inputs |
| @site_mutex | synchronous job for each *Site*|
| @mutex | synchronous job for each *target* host. *Thread*s, generated by *TestCase* instances, call `attack_on_port` method.  Thus, use @mutex if synchronous job is necessary to implement `attack_on_port` method. |

### Implemented methods

There are more methods to which you should pay attention in addition to those in the template.  Generally speaking, the purpose of them is to maintain the consistency among *DB*, *Thread*, and *Process* while *TestCase* runs in multi-threading.  It is a good manner to use those methods in case of calling *DB* updates and external commands.

  * An example of calling `register_banner`

    As mentioned earlier, since *TestCase* runs in multi-threading, you need to foresee many concurrent updates jobs to the same record.  `register_banner` can exclusively act and maintain the consistency of data.

    ```ruby
      register_banner(port, 'Server: Apache/2.2.0')
    ```

  * An example of calling `register_vulnerability`

    This is also to run exclusively and maintain consistency.

    ```ruby
      register_vulnerability(
        evidence,
        name: 'The name of the vulnerability',
        severity: :info, # severity. Choose one from :info, :low, :middle, :high, :critical
        description: 'Detailed description of the vulnerability'
      )
    ```
	


  * An example of calling `create_evidence`

    `create_evidence` namely creates evidence with initial values uniquely set to each of *TestCase*s.

    ```ruby
      evidence = create_evidence(
        @host,
        payload: 'The content of the test, such as used commands or sent data',
        data: 'The test results to prove the existence of vulnerability such as response data'
      )
    ``` 

  * An example of calling `command`

    This is to call external commands.  The method does not access to DB.

    `carash` also has methods that specifically designed to manage child processes as well as Thread.

    Take a look at an example.

    ```ruby
      result = command("ping -c 4 #{@ip}", 'ping.log', ttl: 10)
      result[:out]     # => [String, nil]  : stdout(nil if timed out)
      result[:err]     # => [String, nil]  : stderr(nil if timed out)
      result[:status]  # => [Integer, nil] : exit status(nil if timed out)
      result[:timeout] # => [Boolean]      : timed out or not
    ```

    If you run `command` like this, it execute the first argument as a command and outputs stdout and stderr to a file named 'port.log', in the *TestCase* directory.  When completed, the method returns an Hash object that has stdout, stderr and status.  If not completed within the period specified by `ttl`, the method kills the command process and set `timeout` true.  In that case, `err` and `out` are not returned.  `append` parameter indicates append-mode.  It is by default "true".

### Implementation example

Let us walk you through a more realistic example.  We call it 'http banner grabber', which obtains Server headers by establishing connections with http ports.  It is to apply the action to every http port, so you need to implement `target_ports` and `attack_on_port`.

We will show you the implementation of `target_ports` first.  The example below explains how to extract ports that nmap service detections discover.


```ruby
  def target_ports
    # extract http ports
    @host.tcp.nmap_service('http')
  end
```

We now show you the implementation of `attack_on_port`.  It may appear long and cumbersome, but hopefully its logic should be straightforward.

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

It is a good idea to always use `@console` to see debug messages.  We strongly recommend to make your console and log files informative. `debug`, `info`, `warn` and `error` will certainly make your day.

## Running the implemented *TestCase*

You need to setup a target server and finish port scanning against it.  Like [the Tutorial](TUTORIAL.md) says, load the result of port scanning.  Since the *TestCase* in this example looks for `nmap_service` fields, nmap service scanning is the one you want.

### testcase run

After nmap reports are loaded, run `GreatTest` with `testcase run` command.

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

Do you see what you have expected?  If you encounter problems, debug with `binding.pry`.  When finished solving the problems, refresh *TestCase* with `testsuite reload`.  And try it again.  If successful, try `attack` as well.

### start carash on debug mode

`carash` has a DEBUG mode.  In that mode, after `carash` initialization, you will be able to start pry console under the condition of no active console.  Set `DEBUG=1` and start `carash` to become the debug mode.


```
$ DEBUG=1 carash
*snip*
[1] pry(main)>
```

ActiveRecord is connected to DB in this condition, thus you can access to the database without `binding.pry`.


```
1] pry(main)> Host.first
=> #<Host:0x007f86f05dfda8 id: 1, site_id: 1, ip: "127.0.0.1", test_status: "tested", created_at: 2017-08-01 01:02:03 +0900, updated_at: 2017-08-01 01:02:03 +0900>
[2] pry(main)>
```

This mode may be useful for DB maintenance or to try out new gems for *TestCase*s.

# Conclusion

Hope you will find this tutorial helpful.  For more advanced topics, check out sample *TestSuite*s.

If you made a new TestSuite, please let us know.
