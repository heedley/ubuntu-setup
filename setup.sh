#!/bin/sh

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

# memcached memory usage
memcached_mem=30

goToBase()
{
    cd
    cd ubuntu-setup
    return
}

installBuildTools()
{
    sudo aptitude -y install build-essential libssl-dev libreadline5-dev zlib1g-dev curl
    return
}

installServerUpdates()
{
    sudo aptitude -y update
    sudo aptitude -y safe-upgrade
    sudo aptitude -y full-upgrade
}

installRuby()
{
    sudo aptitude -y install ruby1.8-dev ruby1.8 ri1.8 rdoc1.8 irb1.8 libreadline-ruby1.8 libruby1.8 libopenssl-ruby sqlite3 libsqlite3-ruby1.8
    sudo ln -s /usr/bin/ruby1.8 /usr/bin/ruby
    sudo ln -s /usr/bin/ri1.8 /usr/bin/ri
    sudo ln -s /usr/bin/rdoc1.8 /usr/bin/rdoc
    sudo ln -s /usr/bin/irb1.8 /usr/bin/irb
    return
}

installRubygems()
{
    wget http://rubyforge.org/frs/download.php/45905/rubygems-1.3.1.tgz
    tar xzvf rubygems-1.3.1.tgz
    cd  rubygems-1.3.1
    sudo ruby setup.rb
    sudo ln -s /usr/bin/gem1.8 /usr/bin/gem
    
    goToBase
    rm -rf rubygems-1.3.1*
    return
}

installGems()
{
    gem sources -a http://gems.github.com
    sudo gem install memcache-client hpricot wirble god capistrano thin \
                     fnando-pez rails \
                     --no-ri --no-rdoc
    return
}

installNginx()
{
    # install nginx dependencies
    sudo aptitude -y install libc6 libpcre3 libpcre3-dev libpcrecpp0 libssl0.9.8 libssl-dev zlib1g zlib1g-dev lsb-base
    wget http://downloads.sourceforge.net/pcre/pcre-7.8.tar.bz2?use_mirror=ufpr
    tar xvf pcre-7.8.tar.bz2
    cd pcre-7.8
    ./configure --prefix=/usr/local --enable-static --disable-shared && make && sudo make install
    
    goToBase
    rm -rf pcre*
    
    # install nginx considering Ubuntu paths
    wget -c http://sysoev.ru/nginx/nginx-0.6.35.tar.gz
    tar xvf nginx-0.6.35.tar.gz
    cd nginx-0.6.35
    ./configure \
        --sbin-path=/usr/local/bin/nginx \
        --conf-path=/etc/nginx/nginx.conf \
        --error-log-path=/var/log/nginx/error.log \
        --pid-path=/var/run/nginx.pid \
        --lock-path=/var/lock/nginx.lock \
        --http-log-path=/var/log/nginx/access.log \
        --with-http_dav_module \
        --http-client-body-temp-path=/var/lib/nginx/body \
        --with-http_ssl_module \
        --http-proxy-temp-path=/var/lib/nginx/proxy \
        --with-http_stub_status_module \
        --http-fastcgi-temp-path=/var/lib/nginx/fastcgi \
        --with-debug
    make && sudo make install
    
    goToBase
    rm -rf nginx*
     
    return
}

installMemcache()
{
    # install memcached dependencies
    wget -c http://monkey.org/~provos/libevent-1.4.9-stable.tar.gz
    tar xvf libevent-1.4.9-stable.tar.gz
    cd libevent-1.4.9-stable
    ./configure --prefix=/usr/local --enable-static --disable-shared && make && sudo make install
    
    # register libevent; aparently there's a bug in the latest releases
    # http://alexle.net/archives/275
    echo "/usr/local/lib" | sudo tee  /etc/ld.so.conf.d/libevent-i386.conf
    sudo ldconfig
    
    goToBase
    rm -rf libevent*
    
    # install memcached
    wget -c http://www.danga.com/memcached/dist/memcached-1.2.6.tar.gz
    tar xvf memcached-1.2.6.tar.gz
    cd memcached-1.2.6
    ./configure --prefix=/usr/local && make && sudo make install
    
    goToBase
    rm -rf memcached*
    
    # install libmemcache
    wget -c http://download.tangent.org/libmemcached-0.25.tar.gz
    tar xvf libmemcached-0.25.tar.gz
    cd libmemcached-0.25
    ./configure --prefix=/usr/local --enable-static --disable-shared && make && sudo make install
    
    goToBase
    rm -rf libmemcached*
    
    return
}

installMySQL()
{
    sudo aptitude -y install mysql-server mysql-client libmysqlclient15-dev libmysql-ruby1.8
    return
}

installGit()
{
    sudo aptitude -y install tcl8.4 tk8.4 gettext
    wget -c http://kernel.org/pub/software/scm/git/git-1.6.2.tar.bz2
    tar xvf git-1.6.2.tar.bz2
    cd git-1.6.2
    ./configure --prefix=/usr/local && make && sudo make install
    
    sudo cp contrib/completion/git-completion.bash /home/$username/.git-completion.bash
    sudo chown $username:$username /home/$username/.git-completion.bash
    
    goToBase
    rm -rf git*
    return
}

installSubversion()
{
    sudo aptitude -y install subversion
    return
}

installSecurityTools()
{
    sudo aptitude -y install logwatch denyhosts
    return
}

installPostfix()
{
    sudo aptitude -y install sasl2-bin libsasl2 postfix
    echo "root: $admin_email" | sudo tee -a /etc/aliases
    sudo newaliases
    return
}

copyFiles()
{
    goToBase
    
    cp -R conf /tmp/
    cd /tmp/conf
    rm thin

    i=0
    while test $i != $thin_instances
    do
        port=`expr $i + $thin_port_start`
        echo "server 127.0.0.1:$port;" >> thin
        i=`expr $i + 1`
    done

    for filename in *;
    do 
        cat $filename | ruby -e "puts STDIN.read.gsub(/%username%/sm, '$username')" > $filename
        cat $filename | ruby -e "puts STDIN.read.gsub(/%ssh_port%/sm, '$ssh_port')" > $filename
        cat $filename | ruby -e "puts STDIN.read.gsub(/%domain%/sm, '$domain')"     > $filename
        cat $filename | ruby -e "puts STDIN.read.gsub(/%thin%/sm, '`cat thin`')"    > $filename
    done
    
    
    goToBase
    mv /tmp/conf conf_user
    
    # copy the script file and add it to the boot start
    sudo cp conf_user/nginx /etc/init.d/nginx
    sudo chmod +x /etc/init.d/nginx
    sudo /usr/sbin/update-rc.d -f nginx defaults
    
    # add thin to runlevel
    sudo thin install
    sudo mkdir -p /home/$username/conf
    sudo thin config -C /home/$username/conf/thin.yml -c /home/$username/releases/current/  --servers $thin_instances -e production
    sudo ln -s /home/$username/conf/thin.yml /etc/thin/$username.yml
    
    sudo cp conf_user/iptables.rules /etc/
    sudo cp conf_user/denyhosts.conf /etc/
    sudo cp conf_user/postfix.conf /etc/postfix/main.cf
    sudo cp conf_user/ssh_config /etc/ssh/
    sudo cp conf_user/sshd_config /etc/ssh/
    sudo cp conf_user/nginx.logrotate /etc/logrotate.d/nginx
    
    sudo cp conf_user/nginx.conf /etc/nginx/
    sudo mkdir -p /etc/nginx/sites-enabled
    sudo mkdir -p /var/lib/nginx/body
    
    sudo mkdir -p /home/$username/conf/nginx
    sudo cp conf_user/app.nginx.conf /home/$username/conf/nginx/$username.conf
    sudo ln -s /home/$username/conf/nginx/$username.conf /etc/nginx/sites-enabled/$username.conf
    sudo chown -R $username:$username /home/$username/conf
    
    sudo cp conf_user/pezrc /home/$username/.pezrc
    sudo chown $username:$username /home/$username/.pezrc
    
    sudo cp conf_user/irbrc /home/$username/.irbrc
    sudo chown $username:$username /home/$username/.irbrc
    
    cat /etc/network/interfaces | ruby -e "puts STDIN.read.gsub(/^(iface lo inet loopback)$/, '\\1%spre-up iptables-restore < /etc/iptables.rules' % %(\n))"  > /tmp/interfaces
    sudo mv /tmp/interfaces /etc/network/interfaces
    
    sudo rm -rf conf_user
    
    return
}

addUser()
{
    sudo adduser $username
    echo "$username   ALL=(ALL) ALL" | sudo tee -a /etc/sudoers
    return
}

createRailsApp()
{
    cd /home/$username
    mkdir releases
    cd releases
    rails current
    cd current
    script/generate controller home index
    sudo chown -R $username:$username /home/$username/releases
    
    # start thin & nginx
    sudo /etc/init.d/thin  start
    sudo /etc/init.d/nginx start
    
    echo ""
    echo "-----"
    echo "I created a sample Rails app. Access it at http://$domain/home after DNS has been propagated."
    echo "Here's what I've got at http://127.0.0.1/home"
    echo ""
    curl http://127.0.0.1/home
    echo ""
    echo "And here's the header from the same request:"
    echo ""
    curl -I http://127.0.0.1
    echo ""
    
    return
}

postInstall()
{
    return
}

goToBase
installServerUpdates
addUser
installBuildTools
installSecurityTools
installNginx
installMemcache
installRuby
installRubygems
installGems
installMySQL
installGit
installSubversion
installPostfix
copyFiles
createRailsApp
postInstall

exit 0