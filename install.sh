# user variables
#---------------------------------------------------------------
# gems to be installed
gems="rails fnando-pez wirble god capistrano"

# script variables
#---------------------------------------------------------------
mainTitle="Ubuntu Server Setup"
tmpFile=`tempfile`

# functions
#---------------------------------------------------------------
installRuby()
{
    sudo aptitude -y install ruby1.8-dev ruby1.8 ri1.8 rdoc1.8 irb1.8 libreadline-ruby1.8 libruby1.8 libopenssl-ruby sqlite3 libsqlite3-ruby1.8 rubygems
    sudo ln -s /usr/bin/ruby1.8 /usr/bin/ruby
    sudo ln -s /usr/bin/ri1.8 /usr/bin/ri
    sudo ln -s /usr/bin/rdoc1.8 /usr/bin/rdoc
    sudo ln -s /usr/bin/irb1.8 /usr/bin/irb
    
    return
}

installRubygems()
{
    cd /tmp
    wget http://rubyforge.org/frs/download.php/45905/rubygems-1.3.1.tgz
    tar xzvf rubygems-1.3.1.tgz
    
    cd  rubygems-1.3.1
    sudo ruby setup.rb
    sudo ln -s /usr/bin/gem1.8 /usr/bin/gem
    
    cd /tmp
    rm -rf rubygems-1.3.1*
    
    installGems
    
    return
}

installGems()
{
    gem sources -a http://gems.github.com
    sudo gem install $gems --no-ri --no-rdoc
    
    cd /tmp/conf
    
    sudo cp pezrc /home/$username/.pezrc
    sudo chown $username:$username /home/$username/.pezrc
    
    sudo cp irbrc /home/$username/.irbrc
    sudo chown $username:$username /home/$username/.irbrc
    
    sudo mkdir /home/$username/conf
    sudo cp deploy.rb /home/$username/conf/deploy.rb
    sudo chown -R $username:$username /home/$username/conf/
    
    return
}

installServerUpdates()
{
    sudo aptitude -y update
    sudo aptitude -y safe-upgrade
    sudo aptitude -y full-upgrade
    
    return
}

installBuildTools()
{
    sudo aptitude -y install build-essential libssl-dev libreadline5-dev zlib1g-dev curl
    return
}

installSecurityTools()
{
    sudo aptitude -y install logwatch denyhosts
    
    cat /etc/network/interfaces | ruby -e "puts STDIN.read.gsub(/^(iface lo inet loopback)$/, '\\1%spre-up iptables-restore < /etc/iptables.rules' % %(\n))"  > /tmp/interfaces
    sudo mv /tmp/interfaces /etc/network/interfaces
    
    cd /tmp/conf
    sudo cp iptables.rules /etc/
    sudo cp denyhosts.conf /etc/
    sudo cp ssh_config /etc/ssh/
    sudo cp sshd_config /etc/ssh/
    
    ssh-keygen -f /home/$username/.ssh/id_rsa -t rsa -q -N ''
    sudo chown -R $username:$username /home/$username/.ssh
    touch /home/$username/.ssh/authorized_keys
    
    sudo chmod go-w /home/$username/.ssh
    sudo chmod 600 /home/$username/.ssh/id_rsa
    sudo chmod 600 /home/$username/.ssh/authorized_keys
    sudo chmod 644 /home/$username/.ssh/id_rsa.pub
    
    return
}

addUser()
{
    sudo adduser $username
    echo "$username ALL=(ALL) ALL" | sudo tee -a /etc/sudoers
    
    return
}

installMySQL()
{
    sudo aptitude -y install mysql-server mysql-client libmysqlclient15-dev libmysql-ruby1.8 mytop
    
    sudo gem install mysql --no-ri --no-rdoc
    
    wget http://maatkit.googlecode.com/files/maatkit_3119-1_all.deb
    sudo dpkg -i maatkit_3119-1_all.deb
    
    cd /tmp/conf
    
    sudo cp mysql.conf /etc/mysql/my.cnf
    sudo /etc/init.d/mysql restart
    
    cp database.yml /home/$username/conf/database.yml
    sudo chown $username:$username /home/$username/conf/database.yml
    
    echo ""
    echo "Type your MySQL root password:"
    echo "\
        CREATE DATABASE \`${username}_production\` CHARACTER SET utf8; \
        USE \`${username}_production\`; \
        GRANT ALL PRIVILEGES ON \`${username}_production\`.* TO '$username'@'localhost' IDENTIFIED BY '$mysql_password'; \
        FLUSH PRIVILEGES;" | mysql -u root -p
    
    return
}

installSQLite()
{
    sudo aptitude -y install sqlite3 libsqlite3-ruby1.8
    return
}

installPostfix()
{
    sudo aptitude -y install sasl2-bin libsasl2 postfix
    echo "root: $admin_email" | sudo tee -a /etc/aliases
    sudo newaliases
    return
}

installThin()
{
    sudo gem install thin --no-ri --no-rdoc
    sudo thin install
    sudo mkdir -p /home/$username/conf
    
    sudo thin config -C /home/$username/conf/thin.yml -c /home/$username/website/current/ --servers $thin_instances -e production -p $thin_port_start
    sudo chown $username:$username /home/$username/conf/thin.yml
    
    sudo ln -s /home/$username/conf/thin.yml /etc/thin/$username.yml
    sudo /usr/sbin/update-rc.d -f thin defaults
    
    return
}

installGit()
{
    sudo aptitude -y install git-core
    
    return
}

installSubversion()
{
    sudo aptitude -y install subversion
    return
}

installNginx()
{
    sudo aptitude -y install nginx

    sudo cp nginx.logrotate /etc/logrotate.d/nginx
    
    sudo cp nginx.conf /etc/nginx/
    
    sudo mkdir -p /home/$username/conf/nginx
    sudo cp app.nginx.conf /home/$username/conf/nginx/$username.conf
    sudo ln -s /home/$username/conf/nginx/$username.conf /etc/nginx/sites-available/$username.conf
    sudo ln -s /home/$username/conf/nginx/$username.conf /etc/nginx/sites-enabled/$username.conf
    sudo chown -R $username:$username /home/$username/conf
    sudo rm /etc/nginx/sites-enabled/default
    
    sudo /etc/init.d/nginx restart
    
    return
}

installMemcache()
{
    sudo aptitude -y install memcached libmemcache-dev libmemcache0
    sudo gem install memcache-client system_timer --no-ri --no-rdoc
    
    cd /tmp/conf
    mkdir -p /home/$username/conf
    
    cp memcached.conf /home/$username/conf/memcached.conf
    sudo chown -R $username:$username /home/$username/$conf
    
    sudo rm /etc/memcached.conf
    sudo ln -s /home/$username/conf/memcached.conf /etc/memcached.conf
    
    sudo /etc/init.d/memcached restart
    
    return
}

# create a sample rails app
createRailsApp()
{
    cd /home/$username
    mkdir -p website
    cd website
    rails sample
    cd sample
    sudo chown -R $username:$username /home/$username/website
    ln -s /home/$username/website/sample /home/$username/website/current
    
    # start thin & nginx
    sudo /etc/init.d/thin  restart
    sudo /etc/init.d/nginx restart
    
    return
}

# Replace variables through out config files
prepareConfig()
{
    cp -R conf /tmp/
    cd /tmp/conf
    rm thin 2> /dev/null

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
        cat $filename | ruby -e "puts STDIN.read.gsub(/%mysql_password%/sm, '$mysql_password')"   > $filename
        cat $filename | ruby -e "puts STDIN.read.gsub(/%memcache_port%/sm, '$memcache_port')"     > $filename
        cat $filename | ruby -e "puts STDIN.read.gsub(/%memcache_memory%/sm, '$memcache_memory')" > $filename
    done
}

# Should remove tmp file and clear the screen before exiting
exitScript()
{
    clear
    exit 0
}

# Get return and if is esc or cancel, exit
exitIfCancelOrESC()
{
    action=$1
    
    case $action in
        1) exitScript;;
        255) exitScript;;
        *) return;;
    esac 
}

# Some configurations after all process has been completed
postInstall()
{
    cd /tmp/conf
    cp bash_profile ~/.bash_profile
    source ~/.bash_profile
    
    cp bash_profile /home/$username/.bash_profile
    sudo chown $username:$username /home/$username/.bash_profile
    
    echo "set rebinddelete" > /home/$username/.nanorc
    sudo chown $username:$username /home/$username/.nanorc
    
    return
}

# First, install dialog
#---------------------------------------------------------------
sudo aptitude install dialog

# Then show welcome screen
#---------------------------------------------------------------
dialog --backtitle "$mainTitle" --title "Welcome" \
       --yesno "Hi. This script will setup your Ubuntu Server for Rails apps. Before starting, make sure you're running a fresh Ubuntu install.\n\nThere's no input validation, so be sure of what you're typing.\n\nDo you want to continue?" \
       13 50 2> $tmpFile

input=$?
exitIfCancelOrESC $input
clear

# Ask for username
#---------------------------------------------------------------
dialog  --backtitle "$mainTitle" --title "Creating user account" \
        --inputbox "An user will be created to hold all configuration files and your application.\n\nType the username below." \
        12 50 app 2> $tmpFile

input=$?
exitIfCancelOrESC $input
username=`cat $tmpFile`
clear

# Ask for SSH port
#---------------------------------------------------------------
# TODO: check if the chosen port is being used
#       nc -zv 127.0.0.1 $ssh_port 2>&1
dialog  --backtitle "$mainTitle" --title "SSH port" \
        --inputbox "Is recommended that you change your SSH port to avoid brute force attack. The default port is 22.\n\nWhat port do you want to use? Choose one over port 2000." \
        13 50 22 2> $tmpFile

input=$?
exitIfCancelOrESC $input
ssh_port=`cat $tmpFile`
clear

# Ask for domain
#---------------------------------------------------------------
dialog  --backtitle "$mainTitle" --title "Domain name" \
        --inputbox "What's the domain you're setting up? Can be an IP address." \
        8 50 "domain.com" 2> $tmpFile

input=$?
exitIfCancelOrESC $input
domain=`cat $tmpFile`
clear

# Ask for admin email
#---------------------------------------------------------------
dialog  --backtitle "$mainTitle" --title "Administrator e-mail" \
        --inputbox "What's the admin e-mail?" \
        8 50 "admin@$domain" 2> $tmpFile

input=$?
exitIfCancelOrESC $input
admin_email=`cat $tmpFile`
clear

# Ask for thin instances
#---------------------------------------------------------------
dialog  --backtitle "$mainTitle" --title "Thin instances" \
        --inputbox "How many thin instances do you want to run?" \
        7 50 3 2> $tmpFile

input=$?
exitIfCancelOrESC $input
thin_instances=`cat $tmpFile`
clear

# Ask for thin port
#---------------------------------------------------------------
dialog  --backtitle "$mainTitle" --title "Thin port" \
        --inputbox "What's the starting port number you want your thin instances to use?" \
        8 50 5000 2> $tmpFile

input=$?
exitIfCancelOrESC $input
thin_port_start=`cat $tmpFile`
clear

# Ask for memcache port
#---------------------------------------------------------------
dialog  --backtitle "$mainTitle" --title "Memcache port" \
        --inputbox "What port do you want to run Memcache? The default is 11211." \
        8 50 11211 2> $tmpFile

input=$?
exitIfCancelOrESC $input
memcache_port=`cat $tmpFile`
clear

# Ask for memcache maximum memory usage
#---------------------------------------------------------------
dialog  --backtitle "$mainTitle" --title "Memcache memory usage" \
        --inputbox "How much memory do you want Memcached to use? Please set this value in MB." \
        8 50 30 2> $tmpFile

input=$?
exitIfCancelOrESC $input
memcache_memory=`cat $tmpFile`
clear

# Ask for MySQL password
#---------------------------------------------------------------
dialog  --backtitle "$mainTitle" --title "MySQL user account" \
        --inputbox "An user '$username' will be added to the MySQL. Additionally, a database '${username}_production' will be also created.\n\nPlease type a password for this new MySQL user." \
        13 50 2> $tmpFile

input=$?
exitIfCancelOrESC $input
mysql_password=`cat $tmpFile`
clear

# Disclaimer
#---------------------------------------------------------------
dialog  --backtitle "$mainTitle" --title "Disclaimer" \
        --yesno "I'll start setting up the server now. After this process, I'll restart the SSH service, which means that you'll be disconnected. To reconnect, please use the port $ssh_port as in \"ssh $username@<ip or domain> -p $ssh_port\".\n\nDo you want to continue?" \
        12 50 2> $tmpFile

input=$?
exitIfCancelOrESC $input
clear

# Start the process
#---------------------------------------------------------------
installServerUpdates
installBuildTools
addUser
installRuby
prepareConfig
installRubygems
installSecurityTools
installMySQL
installNginx
installMemcache
installThin
installGit
installSubversion
installPostfix
installSQLite
createRailsApp
postInstall

dialog  --backtitle "$mainTitle" --title "Ubuntu Server Setup Completed" \
        --msgbox "The server has been setup (I hope) and you can access a sample application at http://$domain/home after the domain has been propagated." 8 50

clear
exit 0