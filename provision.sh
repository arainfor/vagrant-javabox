#!/bin/bash

VAGRANT_DIR=/vagrant
HOME_DIR=~/
HOME_BIN_DIR=$HOME_DIR/bin
JDKS=( jdk-6u45-linux-x64.tar.gz jdk-8u65-linux-x64.tar.gz )

installPackage()
{
  local packages=$*
  echo "Installing $packages"
  sudo apt-get install -y $packages >/dev/null 2>&1
}

indent() 
{
  echo -n '    '
}

downloadWithProgress()
{
  local url=$2
  local file=$1
  echo -n "Downloading $file:"
  echo -n "    "
  wget --progress=dot $url 2>&1 | grep --line-buffered "%" | sed -u -e 's/\.//g' | awk '{printf("\b\b\b\b%4s", $2)}'
  echo -ne "\b\b\b\b"
  echo " DONE"
}

download()
{
  local url=$2
  local file=$1
  echo "Downloading $file"
  wget --progress=dot $url >/dev/null 2>&1
}

installPackages()
{
  echo "Installing packages"
  indent; echo 'apt-get update'
  sudo apt-get update >/dev/null 2>&1
  indent; installPackage vim
  indent; installPackage git
  indent; installPackage mc
  #dependencies for pyenv
  indent; installPackage make build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev
  #dependencies for rbenv
  indent; installPackage autoconf bison build-essential libssl-dev libyaml-dev libreadline6-dev zlib1g-dev libncurses5-dev libffi-dev libgdbm3 libgdbm-dev
  indent; installPackage apg
  installMysql
  installNginx
}

createDirs()
{
  echo 'Creating directories'
  indent; echo 'Creating bin directory'
  mkdir $HOME_BIN_DIR
}

downloadJdks()
{
  echo "Downloading jdks"
  for jdk in "${JDKS[@]} 
  do 
    if [ ! -e $jdk ] 
    then 
      indent; echo "There is no $jdk"
      indent; indent; download "$jdk" "http://sof-tech.pl/jdk/$jdk"
    else 
      indent; echo "$jdk is available"
    fi 
  done
}

installJdks()
{
  echo 'Installing jdks'
  for jdk in "${JDKS[@]}
  do 
    indent; echo "Extracting $file"
    tar xvzf ./$jdk >/dev/null 2>&1
    indent; echo 'Cleaning'
    rm $jdk
  done
}

installEnvManagers()
{
  echo 'Installing environment managers (for Java and node.js) '
  indent; echo 'Installing jenv'
  indent; indent; echo 'Clonning from github to ~/.jenv'
  git clone https://github.com/gcuisinier/jenv.git ~/.jenv >/dev/null 2>&1
  indent; indent; echo "Setting environment variables"
  export PATH="$HOME/.jenv/bin:$PATH"
  eval "$(jenv init -)"
  indent; indent; echo 'Make build tools jenv aware'
  message=`jenv enable-plugin ant`
  indent; indent; indent; echo $message
  message=`jenv enable-plugin maven`
  indent; indent; indent; echo $message
  message=`jenv enable-plugin gradle`
  indent; indent; indent; echo $message
  message=`jenv enable-plugin sbt`
  indent; indent; indent; echo $message

  indent; echo 'Installing nodenv'
  indent; indent; echo 'Clonning from github to ~/.nodenv'
  git clone https://github.com/OiNutter/nodenv.git ~/.nodenv >/dev/null 2>&1
  indent; indent; echo 'Installing plugins that provide nodenv install'
  git clone https://github.com/OiNutter/node-build.git ~/.nodenv/plugins/node-build >/dev/null 2>&1
  indent; indent; echo "Setting environment variables"
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
  echo 'Install runtimes using environment managers'
  indent; echo 'Install java'
  for jdk in `ls $HOME_BIN_DIR/ | grep jdk`; do jenv add $HOME_BIN_DIR/$jdk >/dev/null 2>&1; done
  indent; echo 'Set jdk 1.8 globally'
  jenv global 1.8

  indent; echo 'Install node.js'
  nodenv install 4.2.1 >/dev/null 2>&1
  nodenv global 4.2.1

}


installingApp()
{
  local tool_name=$1
  local file=$2
  local url=$3
  local link_src=$4
  local link_target=$5
  echo "Installing $tool_name"
  indent; download $file $url
  indent; echo -n "Extracting $file"
  if [[ "$file" =~ .*tar.gz$ || "$file" =~ .*tgz$ ]]
  then 
    echo " using tar"
    tar xvzf $file >/dev/null 2>&1
  else
    if [[ "$file" =~ .*zip$ ]]
    then
      echo " using unzip"
      unzip $file >/dev/null 2>&1
    else
      echo
      indent; indent; echo "Can't extract $file. Unknown ext"
    fi
  fi
  indent; echo 'Cleaning'
  rm $file
  indent; echo "Creating symbolic link $link_target"
  ln -s $link_src $link_target
}

installingMvn()
{
  installingApp 'apache-maven' \
    apache-maven-3.3.3-bin.tar.gz \
    http://www.eu.apache.org/dist/maven/maven-3/3.3.3/binaries/apache-maven-3.3.3-bin.tar.gz \
    'apache-maven*' \
    apache-maven
}

installingAnt()
{
  installingApp 'apache-ant' \
    apache-ant-1.9.6-bin.tar.gz \
    http://www.eu.apache.org/dist/ant/binaries/apache-ant-1.9.6-bin.tar.gz \
    'apache-ant*' \
    apache-ant
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
  cd $VAGRANT_DIR
  downloadJdks
  echo "Copying jdks to $HOME_BIN_DIR" >/dev/null 2>&1
  cp -r $VAGRANT_DIR/jdk*.tar.gz $HOME_BIN_DIR
  cd $HOME_BIN_DIR  
  installJdks
  installingTools
  installEnvManagers
  updateBashrc
  installRuntimes
}


if [ ! -f "/var/vagrant_provision" ]; then
  sudo touch /var/vagrant_provision
  run
else
  echo "Nothing to do"
fi




