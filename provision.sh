#!/bin/bash

#
#  This script will provision a box for Open Retail development
#

set -e # We exit on any errors! 

VAGRANT_DIR=/vagrant/
HOME_DIR=~/
HOME_BIN_DIR=${HOME_DIR}bin/
DOWNLOAD_DIR=${HOME_DIR}download/
ORACLE_PPA_INSTALL=true

installPackage() {
  local packages=$*
  echo "Installing $packages"
  sudo apt-get install -y "$packages" >/dev/null 2>&1
}

#
# download url file
#
download() {
  local url=$1$2
  local file=$2
  local downloadFile=${DOWNLOAD_DIR}${file}
  if [ ! -e "$downloadFile" ]
  then
    echo "Downloading ${url} to ${downloadFile}"
    wget -P ${DOWNLOAD_DIR} -q --progress=bar "${url}"
  else
    echo "Download skipped for cached file ${downloadFile}" 
  fi
}

installPackages() {
  echo "Installing packages"

  if [ "$ORACLE_PPA_INSTALL" = true ] 
  then
    sudo add-apt-repository -y ppa:webupd8team/java
    echo debconf shared/accepted-oracle-license-v1-1 select true | \
    sudo debconf-set-selections
  
    echo debconf shared/accepted-oracle-license-v1-1 seen true | \
    sudo debconf-set-selections
    echo 'apt-get update'
    sudo apt-get update >/dev/null 2>&1
    installPackage oracle-java6-installer
  else
    echo 'apt-get update'
    sudo apt-get update >/dev/null 2>&1
  fi
  
  
  # These are required but not really version specific
  installPackage subversion cvs git
  
  # Need at least a base java greater than java6 for maven
  installPackage openjdk-7-jre #openjdk-7-jdk
  
  # we should read a list of user defined packages too!
  installPackage vim mc
}

createDirs()
{
  echo 'Creating directories'
  echo 'Creating bin directory'
  mkdir -p ${HOME_BIN_DIR}
  mkdir -p ${DOWNLOAD_DIR}
  mkdir -p ${HOME_DIR}.m2
}

extract() {
  local file=$1
  echo "Extracting ${file}"
  echo "Command:tar -zxvf ${file} -C ${HOME_BIN_DIR}"
  tar -zxf "${file}" -C ${HOME_BIN_DIR}#  >/dev/null 2>&1
}

installJdks() {
  
  if [ "$ORACLE_PPA_INSTALL" = false ] 
  then
    echo "Installing Oracle Standard JDK(s)"
    file=jdk1.6.0_41.tgz
    url="http://156.24.34.140/release/java/"
    download ${url} ${file}
    extract ${DOWNLOAD_DIR}${file}
    echo "Install JDK(s) done!"
  fi
  
  
}

installIbmJdk() {

  file=ibm-java-x86_64-sdk-6.0.14.0.bin;
  #file=ibm-java-jre-6.0-9.1-linux-i386.tgz
  echo "Installing IBM JDK ${file}"
  downloadFile=${DOWNLOAD_DIR}${file};
  download http://156.24.31.131/download/ ${file}
  chmod +x ${downloadFile}
  sudo ln -sf /lib/x86_64-linux-gnu/libc.so.6 /lib/
  echo "Running IBM setup ${downloadFile} silently"
  set +e
  sudo ${downloadFile} -i silent
  set -e
  #extract ${downloadFile}
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
  message="jenv enable-plugin ant"
  echo "$message"
  message="jenv enable-plugin maven"
  echo "$message"
  message="jenv enable-plugin gradle"
  echo "$message"
  message="jenv enable-plugin sbt"
  echo "$message"

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

updateBashrc() {
  echo 'Updating .bashrc'
  backupFile=${HOME_DIR}bashrc.vagrant-javabox
  if [ ! -e  $backupFile ]
  then
    cp ${HOME_DIR}.bashrc ${backupFile}
  fi
  cp ${backupFile} ${HOME_DIR}.bashrc # always start from original backup
  cat ${VAGRANT_DIR}bashrc.template >> ${HOME_DIR}.bashrc
  source ${HOME_DIR}.bashrc
}


installRuntimes()
{
  set +e
  echo "Install runtimes using environment managers"
  echo "Install java from ${HOME_BIN_DIR}"

  for jdk in $(ls ${HOME_BIN_DIR} | grep jdk); 
  do
    jdkFqp=${HOME_BIN_DIR}${jdk}
    echo "Add ${jdkFqp}"
    "$HOME"/.jenv/bin/jenv add "${jdkFqp}" >/dev/null 2>&1;
  done
  echo 'Set jdk 1.6 globally'
  "$HOME"/.jenv/bin/jenv global 1.6

  output=$(update-alternatives --list java)
  while read -r jdkFqp;
  do
    echo "Add ${jdkFqp}"
    "$HOME"/.jenv/bin/jenv add "${jdkFqp}" >/dev/null 2>&1;
  done <<< "$output"

  echo 'Install node.js'
  "$HOME"/.nodenv/bin/nodenv install 4.2.1 >/dev/null 2>&1
  "$HOME"/.nodenv/bin/nodenv global 4.2.1
  set -e
}


installApp()
{
  local tool_name=$1
  local file=$2
  local url=$3
  local link_src=$4
  local link_target=$5
  echo "Installing $tool_name"
  downloadFile=${DOWNLOAD_DIR}${file};
  download "$url" "$file"
  echo -n "Extracting $file"
  
  if [[ "$file" =~ .*tar.gz$ || "$file" =~ .*tgz$ ]]
  then 
    echo " using tar"
    extract "${downloadFile}"
  else
    if [[ "$file" =~ .*zip$ ]]
    then
      echo " using unzip"
      unzip "$file" >/dev/null 2>&1
    else
      echo
      echo "Can't extract $file. Unknown ext"
    fi
  fi
  echo "Creating symbolic link $link_src to $link_target"
  ln -sf "$link_src" "$link_target"
}

installMvn()
{
  installApp 'apache-maven' \
    apache-maven-3.3.9-bin.tar.gz \
    http://supergsego.com/apache/maven/maven-3/3.3.9/binaries/ \
    'apache-maven*' \
    apache-maven

  installPackage maven
  echo "Apache Maven installed"

  cp ${VAGRANT_DIR}toolchains.xml ${HOME_DIR}.m2
  echo "Maven toolchains configured"
}

installAnt()
{
  installApp 'apache-ant' \
    apache-ant-1.9.6-bin.tar.gz \
    http://www.eu.apache.org/dist/ant/binaries/ \
    'apache-ant*' \
    apache-ant
    
  echo "Apache Ant installed"
}

installEclipse() {
  echo "Downloading Eclipse"
  wget -P ${DOWNLOAD_DIR} -q --progress=bar http://www.eclipse.org/downloads/download.php?file=/technology/epp/downloads/release/mars/R/eclipse-jee-mars-R-linux-gtk-x86_64.tar.gz&r=1
  
  extract ${DOWNLOAD_DIR}eclipse-jee-mars-R-linux-gtk-x86_64.tar.gz
}

installIntelliJ() {
  echo "Downloading IntelliJ IDEA"
  wget -P ${DOWNLOAD_DIR} -q --progress=bar http://download.jetbrains.com/idea/ideaIC-15.0.1.exe
  
  extract ${DOWNLOAD_DIR}ideaIC-15.0.1.exe
}

installTools() 
{
  cd $HOME_BIN_DIR
  installMvn
  installAnt
}

info() {
  echo "Provisioning your Base Box for Open Retail development"
}

run() {
  info 
  createDirs
  installPackages
  installJdks
  installIbmJdk
  installTools
  ##installEnvManagers
  ##installRuntimes
  installIntelliJ
  #installEclipse
  updateBashrc
}


run
echo "Provisioning is complete"



