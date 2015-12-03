#!/bin/bash

#
#  This script will provision a box for Open Retail development
#

set -e # We exit on any errors! 

VAGRANT_DIR=/vagrant
HOME_DIR=~/
HOME_BIN_DIR=${HOME_DIR}bin
DOWNLOAD_DIR=${HOME_DIR}download

installPackage()
{
  local packages=$*
  echo "Installing $packages"
  sudo apt-get install -y $packages >/dev/null 2>&1
}

download()
{
  local url=$1
  echo "Downloading $url to ${DOWNLOAD_DIR}"
  wget -P ${DOWNLOAD_DIR} -q --progress=bar $url
}

installPackages()
{
  echo "Installing packages"
  echo 'apt-get update'
  sudo apt-get update >/dev/null 2>&1
  
  # These are required but not really version specific
  installPackage subversion cvs git
  
  # we should read a list of user defined packages too!
  installPackage vim mc
}

createDirs()
{
  echo 'Creating directories'
  echo 'Creating bin directory'
  mkdir -p ${HOME_BIN_DIR}
  mkdir -p ${DOWNLOAD_DIR}
}

extract() {
  local file=$1
  echo "Extracting ${file}"
  echo "Command:tar -zxvf ${file} -C ${HOME_BIN_DIR}"
  tar -zxvf ${file} -C ${HOME_BIN_DIR}  >/dev/null 2>&1
}

installJdks() {
  echo "Installing Standard JDK(s)"
  file=jdk1.6.0_41.tgz
  downloadFile=${DOWNLOAD_DIR}/${file};
  if [ ! -e $downloadFile ] 
  then 
    jdk="http://156.24.34.140/release/java/${file}"
    download "${jdk}"
  fi
  extract ${downloadFile}
  
  echo "Install JDK(s) done!"
}

installIbmJdk() {
  echo "Installing IBM JDK"  
  #file=ibm-java-x86_64-sdk-6.0.14.0.bin;
  file=ibm-java-jre-6.0-9.1-linux-i386.tgz
  downloadFile=${DOWNLOAD_DIR}/${file};
  if [ ! -e $downloadFile ] 
  then 
    download http://156.24.31.131/download/${file}
  fi
  #chmod +x ${downloadFile}
  #sudo ln -s /lib/x86_64-linux-gnu/libc.so.6 /lib/
  #${downloadFile} -i silent
  extract ${downloadFile}
  echo "Install IBM JDK done!"
}

installEnvManagers()
{
  echo 'Installing environment managers (for Java and node.js) '
  echo 'Installing jenv'
  if [ ! -e ~/.jenv ] 
  then
    echo 'Clonning from github to ~/.jenv'
    git clone https://github.com/gcuisinier/jenv.git ~/.jenv >/dev/null 2>&1
  fi
  echo "Setting environment variables"
  export PATH="$HOME/.jenv/bin:$PATH"
  eval "$(jenv init -)"
  echo 'Make build tools jenv aware'
  message=`jenv enable-plugin ant`
  echo $message
  message=`jenv enable-plugin maven`
  echo $message
  message=`jenv enable-plugin gradle`
  echo $message
  message=`jenv enable-plugin sbt`
  echo $message

  echo 'Installing nodenv'
  if [ ! -e ~/.nodenv ] 
  then
    echo 'Clonning from github to ~/.nodenv'
    git clone https://github.com/OiNutter/nodenv.git ~/.nodenv >/dev/null 2>&1
  fi
  if [ ! -e ~/.nodenv/plugins/node-build ] 
  then
    echo 'Installing plugins that provide nodenv install'
    git clone https://github.com/OiNutter/node-build.git ~/.nodenv/plugins/node-build >/dev/null 2>&1
  fi
  echo "Setting environment variables"
  export PATH="$HOME/.nodenv/bin:$PATH"
  eval "$(nodenv init -)"

}

updateBashrc()
{
  echo 'Updating .bashrc'
  cat $VAGRANT_DIR/bashrc.template >> $HOME_DIR/.bashrc
  source $HOME_DIR/.bashrc
}


installRuntimes()
{
  set +e
  echo "Install runtimes using environment managers"
  echo "Install java from ${HOME_BIN_DIR}"
  for jdk in `ls ${HOME_BIN_DIR}/ | grep jdk`; 
  do
    echo "Add ${jdk}" 
    $HOME/.jenv/bin/jenv add ${HOME_BIN_DIR}/${jdk} >/dev/null 2>&1; 
  done
  echo 'Set jdk 1.6 globally'
  $HOME/.jenv/bin/jenv global 1.6

  echo 'Install node.js'
  $HOME/.nodenv/bin/nodenv install 4.2.1 >/dev/null 2>&1
  $HOME/.nodenv/bin/nodenv global 4.2.1
  set -e
}


installingApp()
{
  local tool_name=$1
  local file=$2
  local url=$3
  local link_src=$4
  local link_target=$5
  echo "Installing $tool_name"
  downloadFile=${DOWNLOAD_DIR}/${file};
  if [ ! -e $downloadFile ] 
  then 
    download $url
  fi
  echo -n "Extracting $file"
  
  if [[ "$file" =~ .*tar.gz$ || "$file" =~ .*tgz$ ]]
  then 
    echo " using tar"
    extract ${downloadFile}
  else
    if [[ "$file" =~ .*zip$ ]]
    then
      echo " using unzip"
      unzip $file >/dev/null 2>&1
    else
      echo
      echo "Can't extract $file. Unknown ext"
    fi
  fi
  echo "Creating symbolic link $link_src to $link_target"
  ln -sf $link_src $link_target
}

installingMvn()
{
  installingApp 'apache-maven' \
    apache-maven-3.3.9-bin.tar.gz \
    http://supergsego.com/apache/maven/maven-3/3.3.9/binaries/apache-maven-3.3.9-bin.tar.gz \
    'apache-maven*' \
    apache-maven
    
  echo "Apache Maven installed"
}

installingAnt()
{
  installingApp 'apache-ant' \
    apache-ant-1.9.6-bin.tar.gz \
    http://www.eu.apache.org/dist/ant/binaries/apache-ant-1.9.6-bin.tar.gz \
    'apache-ant*' \
    apache-ant
    
  echo "Apache Ant installed"
}

installingTools() 
{
  cd $HOME_BIN_DIR
  installingMvn
  installingAnt
}

run() {
  createDirs
  installPackages
  installJdks
  installIbmJdk
  installingTools
  installEnvManagers
  updateBashrc
  installRuntimes
}


run




