Ubuntu Setup
============

This script prepares your Ubuntu Server to run Rails apps. Some security settings are also
applied like changing the SSH port and blocking all ports but 80 (www), 443 (https) and your SSH port 
(through Iptables). 

![Script dialog](http://f.simplesideias.com.br/thin-port.png)

A sudoer user will be created to deploy your application. Here's the deployment layout:

    /home/<user>/config/thin.yml          ~> thin configuration file
    /home/<user>/config/database.yml      ~> rails database.yml file
    /home/<user>/config/nginx/<user>.conf ~> nginx application configuration file
    /home/<user>/config/memcached.conf    ~> memcached configuration file
    /home/<user>/website                  ~> Capistrano deployment directory
    /home/<user>/config/deploy.rb         ~> Capistrano deploy.rb

Thin, Nginx and Memcached are added to boot start, so you're application will be automatically started
after restarting the server. 

**ATTENTION:** I ran this script in a Parallels Ubuntu install, without any problem. 
I'm still developing my application, so I haven't had the chance to test it in a real VPS.

Usage
-----

Before you start, make sure you're running this script in a fresh Ubuntu install.

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
    
Run `sh install.sh` and answer to the dialogs.

### Deploying the application

First, run the command `capify` in your project root.

    capify .

Copy the sample Capistrano recipe from `$HOME/conf/deploy.rb` on your server
to `your-project/conf/deploy.rb`.

You need to change the repository and SCM (which defaults to Git). When you're done just run the 
following commands:

    cap deploy:setup # just the first time
    cap deploy

You may need to add the server SSH key to your SCM server. Alternatively you can set up the [SSH Agent](http://upc.lbl.gov/docs/user/sshagent.html).

What will be installed?
-----------------------

* Ruby
* Nginx
* Memcached
* MySQL and analysis tools
    - mytop ~ <http://jeremy.zawodny.com/mysql/mytop/>
    - Maatkit ~ <http://www.maatkit.org/>
* Git
* Subversion
* Postfix
* Denyhosts & Logwatch

Troubleshooting
---------------

### When I start the Denyhosts daemon my IP is added to the `hosts.deny` list. What should I do?

Erase your `/var/log/auth.log` and remove all files under `/var/lib/denyhosts`. The following command should do the trick:

    su root
    > /var/log/auth.log
    rm /var/lib/denyhosts/*

You also need to remove your IP from `/etc/hosts.deny`.

TODO
----

* Script should configure Postfix
* Create God monitoring scripts

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