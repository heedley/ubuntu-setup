Ubuntu Setup
============

This script prepares your Ubuntu Server to run Rails apps. Some security settings are also
applied like changing the SSH port and blocking all ports but 80 (www), 443 (https) and your SSH port. 

A sudoer user will be created to deploy your application. Here's the deployment layout:

    /home/<user>/config/thin.yml          ~> your thin configuration file
    /home/<user>/config/nginx/<user>.conf ~> your nginx application configuration file
    /home/<user>/releases                 ~> your Capistrano releases directory

Thin and Nginx are added to boot start, so you're application will be automatically started
after restarting the server. 

**ATTENTION:** I ran this script in a Parallels Ubuntu install, without any problem. 
I'm still developing my application, so I haven't had the chance to test it in a real VPS.

Usage
-----

Before you start, make sure you're runing this script in a fresh Ubuntu install.

You should be logged as root. If you have a VPS, then you probably have a root account.
If you're running an Ubuntu Server on your own, you have to enable the root account.
Just run `sudo passwd` and set your root password.

Now download the script installer and uncompress it.

    su root
    cd ~
    wget http://github.com/fnando/ubuntu-setup/tarball/master -O ubuntu-setup.tar.gz
    tar xvf ubuntu-setup
    rm ubuntu-setup.tar.gz
    mv fnando-ubuntu-setup* ubuntu-setup
    cd ubuntu-setup
    
Open the file `setup.sh` and configure the variables that will be used across the script. 
These are the default values:

    # set the new user that will be created
    username="app"

    # switch ssh port to avoid exploits
    ssh_port=222

    # define the number of thin instances
    thin_instances=3

    thin_port_start=3000

    # set an admin email
    admin_email="root@localhost"

    # set your domain (without www)
    domain="domain.com"

After setting these variables run the script with `sudo sh setup.sh`

What will be installed?
-----------------------

* Ruby
* Nginx
* Memcached
* MySQL
* Git
* Subversion
* Postfix
* Denyhosts
* Logwatch

Things this script doesn't do yet
---------------------------------

* Configure Postfix
* Tune MySQL
* Add memcached to runlevel
* Create God monitoring scripts
* Optionally set up SSL on Nginx
* Prepare Capistrano recipe

LICENSE:
--------

(The MIT License)

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.