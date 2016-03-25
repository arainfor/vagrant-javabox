# vagrant-javabox

1. Install Vagrant on your Host. (http://www.vagrantup.com/downloads)
2. Install VirtualBox on your Host. (https://www.virtualbox.org/)
3. Make sure you have a Box installed. "vagrant box add ubuntu/trusty64"
4. Make or change to directory for this workspace. "mkdir myTestVagrantJavabox; cd myTestVagrantJavabox"
5. Clone this repository in your workspace. "git clone https://github.com/arainfor/vagrant-javabox.git"
6. Within your workspace change to the new folder vagrant-javabox (this project). "cd vagrant-javabox"
7. In your workspace start and provision the vagrant environment. "vagrant up"
8. After the provisioning is complete it's a good idea to restart the box. "vagrant halt; vagrant up"
9. Login to your box with "vagrant ssh" or use your favorite ssh client. "ssh vagrant@localhost -p 2222"
10. Start IntelliJ IDEA. "/home/vagrant/bin/idea-IC-145.258.11/bin/idea.sh &"
11. After some initial setup (just use defaults) open NEOS project (trunk) from SVN: https://156.24.30.205/svn/neos-src/neos/

Notes:
The Linux Host Box will be provisioned as described in provision.sh.  It's a bit on the heavy side but should create a consistant setup every time.

We load IntelliJ IDEA Community Edition by default.  If you want Eclipse look at the 'run' function in provision.sh


    default: SSH address: 127.0.0.1:2222
    default: SSH username: vagrant
    default: SSH auth method: private key

