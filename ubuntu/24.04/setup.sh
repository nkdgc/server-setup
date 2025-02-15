#!/bin/bash

SSH_AUTHORIZED_KEY_URL="https://raw.githubusercontent.com/nkdgc/server-setup/refs/heads/main/authorized_keys/authorized_keys"
VIMRC_URL="https://raw.githubusercontent.com/nkdgc/server-setup/refs/heads/main/vim/linux-vimrc"
BASHRC_URL="https://raw.githubusercontent.com/nkdgc/server-setup/refs/heads/main/bash/dot_bashrc"
DIRCOLORS_URL="https://raw.githubusercontent.com/nkdgc/server-setup/refs/heads/main/bash/dot_dircolors"
TMUXCONF_URL="https://raw.githubusercontent.com/nkdgc/server-setup/refs/heads/main/tmux/tmux.conf"

# Check if the script is running as the root user
if [ "$(whoami)" != "root" ]; then
    echo "Error: This script must be run as the root user. Please run the script with 'sudo' or as the root user."
    exit 1
fi

silent=false
light=false
reboot=false

while (( $# > 0 ))
do
  case $1 in
    # --- silent ---
    --silent)
      silent=true
      ;;
    # --- light ---
    --light)
      light=true
      ;;
    # --- reboot ---
    --reboot)
      reboot=true
      ;;
    # --- hostname ---
    -h | --hostname | --hostname=*)
      if [[ "$1" =~ ^--hostname= ]]; then
        hostname=$(echo $1 | sed -e 's/^--hostname=//')
      elif [[ -z "$2" ]] || [[ "$2" =~ ^-+ ]]; then
        echo "'hostname' requires an argument." 1>&2
        exit 1
      else
        hostname="$2"
        shift
      fi
      ;;
    # --- user ---
    -h | --user | --user=*)
      if [[ "$1" =~ ^--user= ]]; then
        user=$(echo $1 | sed -e 's/^--user=//')
      elif [[ -z "$2" ]] || [[ "$2" =~ ^-+ ]]; then
        echo "'user' requires an argument." 1>&2
        exit 1
      else
        user="$2"
        shift
      fi
      ;;
    # --- other -> ERROR ---
    *)
      echo "unknown option: $1" 1>&2
      exit 1
      ;;
  esac
  shift
done

echo "----- debug -----"
echo "silent   : $silent"
echo "light    : $light"
echo "reboot   : $reboot"
echo "hostname : $hostname"
echo "user     : $user"

function exec_cmd_rc_0(){
  cmd=$1
  echo "<----- COMMAND: ${cmd} ----->"
  eval ${cmd}
  rc=$?
  if [ ${rc} -eq 0 ]; then
    echo "<----- RC: ${rc} ----->"
  else
    echo "<----- [ERROR] RC: ${rc} ----->"
    exit 1
  fi
}

# Confirm and change the hostname
if [ -n "$hostname" ]; then
  echo "############### change hostname ###############"
  if "$silent"; then
    exec_cmd_rc_0 "hostnamectl set-hostname ${hostname}"
  else
    read -p "Change the hostname to ${hostname}? (Y/n): " confirm
    case "$confirm" in
      [yY]*)
        echo "Changing hostname to $hostname..."
        exec_cmd_rc_0 "hostnamectl set-hostname ${hostname}"
        ;;
      *)
        echo "Exiting script."
        exit 0
        ;;
    esac
  fi
fi

echo "############### change timezone ###############"
exec_cmd_rc_0 "timedatectl set-timezone Asia/Tokyo"

echo "############### bashrc ###############"
exec_cmd_rc_0 "curl ${BASHRC_URL} >> ~/.bashrc"
if [ -n "$user" ]; then
  exec_cmd_rc_0 "cp ~/.bashrc /home/${user}/.bashrc"
  exec_cmd_rc_0 "chown ${user}:${user} /home/${user}/.bashrc"
fi

echo "############### dircolors ###############"
exec_cmd_rc_0 "curl ${DIRCOLORS_URL} >> ~/.dircolors"
if [ -n "$user" ]; then
  exec_cmd_rc_0 "cp ~/.dircolors /home/${user}/.dircolors"
  exec_cmd_rc_0 "chown ${user}:${user} /home/${user}/.dircolors"
fi

echo "############### create ssh key ###############"
exec_cmd_rc_0 "ssh-keygen -t rsa -N '' -f /root/.ssh/id_rsa"
if [ -n "$user" ]; then
  exec_cmd_rc_0 "su - ${user} -c \"ssh-keygen -t rsa -N '' -f /home/${user}/.ssh/id_rsa\""
fi

echo "############### add authorized key ###############"
exec_cmd_rc_0 "curl ${SSH_AUTHORIZED_KEY_URL} >> ~/.ssh/authorized_keys"
# delete blank line
exec_cmd_rc_0 "sed -i '/^$/d' ~/.ssh/authorized_keys"
if [ -n "$user" ]; then
  exec_cmd_rc_0 "cp ~/.ssh/authorized_keys /home/${user}/.ssh/authorized_keys"
  exec_cmd_rc_0 "chown ${user}:${user} /home/${user}/.ssh/authorized_keys"
fi

echo "############### apt update, upgrade, install vim/git/tmux/... ###############"
exec_cmd_rc_0 "apt update"
exec_cmd_rc_0 "dpkg --configure -a"
exec_cmd_rc_0 "apt upgrade -y"
if "$light"; then
  exec_cmd_rc_0 "apt install -y vim git traceroute tmux curl net-tools zip unzip postgresql-client apache2-utils"
else
  exec_cmd_rc_0 "apt install -y vim git traceroute tmux curl net-tools zip unzip"
fi
# memo:
# - apache2-utils for Apache Bench (ab)

echo "############### setup git ###############"
exec_cmd_rc_0 "git config --global core.editor vim"
if [ -n "$user" ]; then
  exec_cmd_rc_0 "su - ${user} -c \"git config --global core.editor vim\""
fi

# echo "############### allow ssh root login"
# SSH_BASE_DIR="/etc/ssh"
# cat ${SSH_BASE_DIR}/sshd_config | sed -e "s/^#PermitRootLogin.*$/PermitRootLogin yes/g" > ${SSH_BASE_DIR}/sshd_config.mod
# mv ${SSH_BASE_DIR}/sshd_config.mod ${SSH_BASE_DIR}/sshd_config
# 
# systemctl restart sshd

echo "############### .vimrc ###############"
exec_cmd_rc_0 "curl ${VIMRC_URL} > ~/.vimrc"
if [ -n "$user" ]; then
  exec_cmd_rc_0 "cp ~/.vimrc /home/${user}/.vimrc"
  exec_cmd_rc_0 "chown ${user}:${user} /home/${user}/.vimrc"
fi

echo "############### .tmux.conf ###############"
exec_cmd_rc_0 "curl ${TMUXCONF_URL} > ~/.tmux.conf"
if [ -n "$user" ]; then
  exec_cmd_rc_0 "cp ~/.tmux.conf /home/${user}/.tmux.conf"
  exec_cmd_rc_0 "chown ${user}:${user} /home/${user}/.tmux.conf"
fi

# echo "############### install asciinema"
# apt-add-repository -y ppa:zanchey/asciinema
# apt-get update
# apt-get install -y asciinema

# echo "############### create network file template"
# 
# cat <<EOF > /root/99-config.yaml
# network:
#   ethernets:
#     ens160:
#       # dhcp4: true
#       addresses:
#       - 192.168.1.2/24
#       routes:
#       - to: 10.0.0.0/8
#         via: 192.168.1.1
#     ens192:
#       addresses:
#       - 10.0.0.5/24
#     ens224:
#       addresses:
#       - 192.168.2.2/24
#       gateway4: 192.168.2.1
#       nameservers:
#         addresses:
#         - 10.0.0.253
#         search:
#         - psodemo.net
#   vlans:
#     ens192.100:
#       id: 100
#       link: ens192
#       addresses: [192.168.100.1/24]
#   version: 2
#   renderer: NetworkManager
# EOF
# 
# chmod 644 /root/99-config.yaml

if ! "$light"; then
  echo "############### install docker engine ###############"
  exec_cmd_rc_0 "apt-get update"
  exec_cmd_rc_0 "apt-get install ca-certificates curl gnupg lsb-release"
  exec_cmd_rc_0 "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg"
  exec_cmd_rc_0 "echo \"deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable\" | tee /etc/apt/sources.list.d/docker.list > /dev/null"
  exec_cmd_rc_0 "apt-get update"
  exec_cmd_rc_0 "apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin"
  if [ -n "$user" ]; then
    exec_cmd_rc_0 "usermod -aG docker ${user}"
  fi
  exec_cmd_rc_0 "docker --version"   # Check
fi

if ! "$light"; then
  echo "############### install aws cli ###############"
  exec_cmd_rc_0 "curl https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o awscliv2.zip"
  exec_cmd_rc_0 "unzip awscliv2.zip"
  exec_cmd_rc_0 "./aws/install --bin-dir /usr/local/bin --install-dir /usr/local/aws-cli --update"
  exec_cmd_rc_0 "aws --version"           # Check
  if [ -n "$user" ]; then
    exec_cmd_rc_0 "su - ${user} aws --version"           # Check
  fi
fi
# exec_cmd_rc_0 "curl https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o awscliv2.zip"
# exec_cmd_rc_0 "unzip awscliv2.zip"
# exec_cmd_rc_0 "sudo ./aws/install"
# exec_cmd_rc_0 "aws --version"           # Check

# echo "############### install terraform"
# exec_cmd_rc_0 "wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg"
# exec_cmd_rc_0 "echo \"deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main\" | sudo tee /etc/apt/sources.list.d/hashicorp.list"
# exec_cmd_rc_0 "sudo apt update && sudo apt install -y terraform"
# exec_cmd_rc_0 "terraform -v"            # Check

if ! "$light"; then
  echo "############### install asdf ###############"
  if [ -z "$user" ]; then
    exec_cmd_rc_0 "git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.14.1"
    exec_cmd_rc_0 "echo '. "\$HOME/.asdf/asdf.sh"' >> ~/.bashrc"
    exec_cmd_rc_0 "echo '. "\$HOME/.asdf/completions/asdf.bash"' >> ~/.bashrc"
  else
    exec_cmd_rc_0 "su - ${user} -c \"git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.14.1\""
    exec_cmd_rc_0 "su - ${user} -c \"echo '. "\\\$HOME/.asdf/asdf.sh"' >> ~/.bashrc\""
    exec_cmd_rc_0 "su - ${user} -c \"echo '. "\\\$HOME/.asdf/completions/asdf.bash"' >> ~/.bashrc\""
  fi
fi

if ! "$light"; then
  echo "############### install terraform with asdf ###############"
  if [ -z "$user" ]; then
    exec_cmd_rc_0 "source ~/.asdf/asdf.sh && asdf plugin add terraform"
    exec_cmd_rc_0 "source ~/.asdf/asdf.sh && asdf list all terraform"
    exec_cmd_rc_0 "source ~/.asdf/asdf.sh && asdf install terraform latest"
    exec_cmd_rc_0 "source ~/.asdf/asdf.sh && asdf list terraform"
    exec_cmd_rc_0 "source ~/.asdf/asdf.sh && asdf global terraform latest"
    exec_cmd_rc_0 "source ~/.asdf/asdf.sh && asdf list terraform"
    exec_cmd_rc_0 "source ~/.asdf/asdf.sh && sh -c 'terraform version'"
  else
    exec_cmd_rc_0 "su - ${user} -c \"source /home/${user}/.asdf/asdf.sh && asdf plugin add terraform\""
    exec_cmd_rc_0 "su - ${user} -c \"source /home/${user}/.asdf/asdf.sh && asdf list all terraform\""
    exec_cmd_rc_0 "su - ${user} -c \"source /home/${user}/.asdf/asdf.sh && asdf install terraform latest\""
    exec_cmd_rc_0 "su - ${user} -c \"source /home/${user}/.asdf/asdf.sh && asdf list terraform\""
    exec_cmd_rc_0 "su - ${user} -c \"source /home/${user}/.asdf/asdf.sh && asdf global terraform latest\""
    exec_cmd_rc_0 "su - ${user} -c \"source /home/${user}/.asdf/asdf.sh && asdf list terraform\""
    exec_cmd_rc_0 "su - ${user} -c \"source /home/${user}/.asdf/asdf.sh && sh -c 'terraform version'\""
  fi
fi

# echo "############### install python3.12 ###############"
# exec_cmd_rc_0 "sudo apt install -y python3.12 python3.12-venv"
# exec_cmd_rc_0 "python3 --version"       # Check
# exec_cmd_rc_0 "python3 -m venv -h"      # Check

# echo "############### install pyenv ###############"
# exec_cmd_rc_0 "curl https://pyenv.run | bash"
#
# add_bashrc='
# export PYENV_ROOT="$HOME/.pyenv"
# [[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
# eval "$(pyenv init -)"
# eval "$(pyenv virtualenv-init -)"'
#
# exec_cmd_rc_0 'echo "${add_bashrc}" >> .bashrc'
# exec_cmd_rc_0 "export PYENV_ROOT=\"$HOME/.pyenv\""
# exec_cmd_rc_0 "export PATH=\"$PYENV_ROOT/bin:$PATH\""
# exec_cmd_rc_0 "pyenv --version"
#
# echo "############### install build packages for pyenv ###############"
# exec_cmd_rc_0 "sudo apt install -y build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev curl git libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-devliblzma-dev"
#
# echo "############### install python 3.13:latest ###############"
# exec_cmd_rc_0 "pyenv install -l"
# exec_cmd_rc_0 "pyenv install 3.13"
# exec_cmd_rc_0 "pyenv versions"
# exec_cmd_rc_0 "pyenv global 3.13"
# exec_cmd_rc_0 "pyenv versions"

if ! "$light"; then
  echo "############### install python with asdf ###############"
  if [ -z "$user" ]; then
    exec_cmd_rc_0 "source ~/.asdf/asdf.sh && asdf plugin add python"
    exec_cmd_rc_0 "source ~/.asdf/asdf.sh && asdf list all python"
    exec_cmd_rc_0 "apt install -y build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev curl git libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev"
    exec_cmd_rc_0 "source ~/.asdf/asdf.sh && asdf install python latest"
    exec_cmd_rc_0 "source ~/.asdf/asdf.sh && asdf list python"
    exec_cmd_rc_0 "source ~/.asdf/asdf.sh && asdf global python latest"
    exec_cmd_rc_0 "source ~/.asdf/asdf.sh && asdf list python"
    exec_cmd_rc_0 "source ~/.asdf/asdf.sh && sh -c 'python --version'"
    # --- install git-remote-codecommit (for workshop-studio) ---
    exec_cmd_rc_0 "source ~/.asdf/asdf.sh && pip install git-remote-codecommit"
  else
    exec_cmd_rc_0 "su - ${user} -c \"source /home/${user}/.asdf/asdf.sh && asdf plugin add python\""
    exec_cmd_rc_0 "su - ${user} -c \"source /home/${user}/.asdf/asdf.sh && asdf list all python\""
    exec_cmd_rc_0 "apt install -y build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev curl git libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev"
    exec_cmd_rc_0 "su - ${user} -c \"source /home/${user}/.asdf/asdf.sh && asdf install python latest\""
    exec_cmd_rc_0 "su - ${user} -c \"source /home/${user}/.asdf/asdf.sh && asdf list python\""
    exec_cmd_rc_0 "su - ${user} -c \"source /home/${user}/.asdf/asdf.sh && asdf global python latest\""
    exec_cmd_rc_0 "su - ${user} -c \"source /home/${user}/.asdf/asdf.sh && asdf list python\""
    # install git-remote-codecommit (for workshop-studio)
    exec_cmd_rc_0 "su - ${user} -c \"source /home/${user}/.asdf/asdf.sh && pip install git-remote-codecommit\""
  fi
fi

if "$reboot"; then
  shutdown -r now
fi
