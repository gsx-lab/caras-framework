# Caras-Framework

Caras-Framework is an automation framework for vulnerability scanning.


## Overview

### Job control application for vulnerability scanning

This framework automatically executes a set of various *TestCase*s for vulnerability scanning in a predefined order. *TestCase*s form a cluster tree where each child depends on its parent.
Caras-Framework accumulates the running status of *TestCase*s and manages them efficiently.

![running status](docs/images/running-status.png)


### Ruby programmable vulnerability scanning

Programming a *TestCase* in Ruby is very [simple](docs/DEVELOP_TEST_SUITES.md#implementation-example).

![simple TestCase](docs/images/simple-testcase.png)

### Extensible

A set of dependant *TestCase*s makes up a *TestSuite*. *TestSuite*s can be switched back and forth at the series of vulnerability scanning. Generating reports or commands are also customizable.


## Limitations

### Not comprehensive

Unlike well known security scanners such as [Nexpose](https://www.rapid7.com/products/nexpose/), [OpenVAS](http://www.openvas.org), [Nessus](https://www.tenable.com/products/nessus-vulnerability-scanner) and [Retina](https://www.beyondtrust.com/products/retina-network-security-scanner/), Caras-Framework has no predefined *TestSuite*s. You need to add your own *TestSuite*s. We provide sample *TestSuite*s, though premature. If comprehensive testing is called for, there are a lot of other tools that suffice the goal.


### No GUI

Caras-Framework has no Web UI. CUI is only choice. The framework may seem friendly to those who are familiar with operations via terminal. It is not for GUI lover.

## Summary

Caras-Framework makes your pen-testing life more productive.


# Installation

Docker is a good way to start the framework. We do not support running Caras-Framework natively on Windows platform. Therefore, if you want to run this framework on Windows you need to use Docker.

* [Docker](docs/INSTALL.md#install-on-docker)

We recommend to install the framework in the native environment to develop *TestSuite*s or extensions.

* [macOS](docs/INSTALL.md#install-on-macos)
* [Kali Linux](docs/INSTALL.md#install-on-kali-linux)


# Tutorial

Does `carash` successfully start like below?
![carash starts](docs/images/carash-starts.png)

Congratulations. Let's start for vulnerability scanning.

[Tutorial](docs/TUTORIAL.md)


# *TestSuite*s development

Let's start learning how to develop *TestSuite*s.

[How to write your own *TestSuite*s](docs/DEVELOP_TEST_SUITES.md)


# License

Caras-Framework by Global Security Experts Inc. is licensed under the Apache License, Version2.0
