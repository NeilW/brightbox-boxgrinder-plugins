# BoxGrinder Brightbox Plugins

This archive integrates the Boxgrinder project [boxgrinder.org](http://www.boxgrinder.org) with the [Brightbox cloud CLI tools] (http://github.com/brightbox/brightbox-cli)

### Supported OSes

Brightbox supports all the OSs that Boxgrinder can generate and adds a plugin to generate Scientific Linux images - so you can get Enterprise Linux version 6 today.

### Requirements

* A RPM based build machine - registering the boxgrinder appliance image with the Brightbox cloud works fine.
* This plugin gem installed.

### Installing

* `sudo gem install brightbox-boxgrinder-plugins` to install Brightbox CLI tools and the plugins onto the machine.
* `sudo brightbox-config client_add cli-xxxxx secretdetails` to add the api client details that allow access to the Brightbox cloud api.

### Usage

Create an appliance configuration file, then call the plugins as in the following example.

    boxgrinder-build --plugins brightbox-boxgrinder-plugins sl-basic.appl -p bbcloud -d bbcloud

To build an i386 version use:

    setarch i386 boxgrinder-build --plugins brightbox-boxgrinder-plugins sl-basic.appl -p bbcloud -d bbcloud

Obviously you are not limited to Scientific Linux and can create Fedora, RHEL or CentOS images too.

