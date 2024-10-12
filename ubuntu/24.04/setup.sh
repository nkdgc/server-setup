#!/bin/bash

NON_ROOT_USERNAME="ubuntu"
SSH_AUTHORIZED_KEY_URL="https://raw.githubusercontent.com/nkdgc/server-setup/refs/heads/main/authorized_keys/authorized_keys"
VIMRC_URL="https://raw.githubusercontent.com/nkdgc/server-setup/refs/heads/main/vim/linux-vimrc"
BASHRC_URL="https://raw.githubusercontent.com/nkdgc/server-setup/refs/heads/main/bashrc/bashrc.sh"
TMUXCONF_URL="https://raw.githubusercontent.com/nkdgc/server-setup/refs/heads/main/tmux/tmux.conf"

# # Check if the script is running as the root user
# if [ "$(whoami)" != "root" ]; then
#     echo "Error: This script must be run as the root user. Please run the script with 'sudo' or as the root user."
#     exit 1
# fi

if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
    echo "Error: This script requires exactly one argument (the hostname), and an optional --silent flag."
    echo "Usage: $0 <hostname> [--silent]"
    exit 1
fi

function exec_cmd_rc_0(){
  cmd=$1
  echo ""
  echo "<----- COMMAND: ${cmd} ----->"
  echo ""
  eval ${cmd}
  rc=$?
  if [ ${rc} -eq 0 ]; then
    echo ""
    echo "<----- RC: ${rc} ----->"
  else
    echo ""
    echo "<----- [ERROR] RC: ${rc} ----->"
    exit 1
  fi
}

# Confirm and change the hostname
echo "############### change hostname ###############"
hostname="$1"
silent_mode=false
if [ "$#" -eq 2 ] && [ "$2" == "--silent" ]; then
    silent_mode=true
fi
if [ "$silent_mode" = false ]; then
  read -p "Change the hostname to ${hostname}? (Y/n): " confirm
  case "$confirm" in
    [yY]*)
      echo "Changing hostname to $hostname..."
      exec_cmd_rc_0 "sudo hostnamectl set-hostname ${hostname}"
      ;;
    *)
      echo "Exiting script."
      exit 0
      ;;
  esac
else
    echo "Silent mode enabled. Changing hostname to $hostname..."
    exec_cmd_rc_0 "sudo hostnamectl set-hostname ${hostname}"
fi

echo "############### change timezone ###############"
exec_cmd_rc_0 "sudo timedatectl set-timezone Asia/Tokyo"

echo "############### bashrc ###############"
exec_cmd_rc_0 "sudo sh -c \"curl ${BASHRC_URL} >> /root/.bashrc\""
exec_cmd_rc_0 "curl ${BASHRC_URL} >> /home/${NON_ROOT_USERNAME}/.bashrc"

echo "############### create ssh key ###############"
exec_cmd_rc_0 "ssh-keygen -t rsa -N '' -f /home/${NON_ROOT_USERNAME}/.ssh/id_rsa"

echo "############### add authorized key ###############"
exec_cmd_rc_0 "curl ${SSH_AUTHORIZED_KEY_URL} >> /home/${NON_ROOT_USERNAME}/.ssh/authorized_keys"
# delete blank line
exec_cmd_rc_0 "sed -i '/^$/d' /home/${NON_ROOT_USERNAME}/.ssh/authorized_keys"

# echo "############### change apt repository to ftp.riken.jp"
# perl -p -i.bak -e 's%(deb(?:-src|)\s+)https?://(?!archive\.canonical\.com|security\.ubuntu\.com)[^\s]+%$1http://ftp.riken.jp/Linux/ubuntu/%' /etc/apt/sources.list

echo "############### apt update, upgrade, install vim/git/tmux/... ###############"
exec_cmd_rc_0 "sudo apt update"
exec_cmd_rc_0 "sudo apt upgrade -y"
exec_cmd_rc_0 "sudo apt install -y vim git traceroute tmux curl net-tools unzip"

echo "############### setup git ###############"
exec_cmd_rc_0 "git config --global core.editor vim"

# echo "############### allow ssh root login"
# SSH_BASE_DIR="/etc/ssh"
# cat ${SSH_BASE_DIR}/sshd_config | sed -e "s/^#PermitRootLogin.*$/PermitRootLogin yes/g" > ${SSH_BASE_DIR}/sshd_config.mod
# mv ${SSH_BASE_DIR}/sshd_config.mod ${SSH_BASE_DIR}/sshd_config
# 
# systemctl restart sshd

echo "############### .vimrc ###############"
exec_cmd_rc_0 "sudo sh -c \"curl ${VIMRC_URL} > /root/.vimrc\""
exec_cmd_rc_0 "sudo cp /root/.vimrc /home/${NON_ROOT_USERNAME}/.vimrc"
exec_cmd_rc_0 "sudo chown ${NON_ROOT_USERNAME}:${NON_ROOT_USERNAME} /home/${NON_ROOT_USERNAME}/.vimrc"

echo "############### .tmux.conf ###############"
exec_cmd_rc_0 "sudo sh -c \"curl ${TMUXCONF_URL} > /root/.tmux.conf\""
exec_cmd_rc_0 "sudo sh -c \"cp /root/.tmux.conf /home/${NON_ROOT_USERNAME}/.tmux.conf\""
exec_cmd_rc_0 "sudo sh -c \"chown ${NON_ROOT_USERNAME}:${NON_ROOT_USERNAME} /home/${NON_ROOT_USERNAME}/.tmux.conf\""

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

echo "############### install docker engine ###############"
exec_cmd_rc_0 "sudo apt-get update"
exec_cmd_rc_0 "sudo apt-get install ca-certificates curl gnupg lsb-release"
exec_cmd_rc_0 "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg"
exec_cmd_rc_0 "echo \"deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable\" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null"
exec_cmd_rc_0 "sudo apt-get update"
exec_cmd_rc_0 "sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin"
exec_cmd_rc_0 "sudo usermod -aG docker ${NON_ROOT_USERNAME}"
exec_cmd_rc_0 "sudo docker --version"   # Check

echo "############### install aws cli ###############"
exec_cmd_rc_0 "curl https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o awscliv2.zip"
exec_cmd_rc_0 "unzip awscliv2.zip"
exec_cmd_rc_0 "sudo ./aws/install"
exec_cmd_rc_0 "aws --version"           # Check

# echo "############### install terraform"
# exec_cmd_rc_0 "wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg"
# exec_cmd_rc_0 "echo \"deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main\" | sudo tee /etc/apt/sources.list.d/hashicorp.list"
# exec_cmd_rc_0 "sudo apt update && sudo apt install -y terraform"
# exec_cmd_rc_0 "terraform -v"            # Check

echo "############### install asdf ###############"
exec_cmd_rc_0 "git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.14.1"
exec_cmd_rc_0 "echo '. "\$HOME/.asdf/asdf.sh"' >> ~/.bashrc"
exec_cmd_rc_0 '. "$HOME/.asdf/asdf.sh"'
exec_cmd_rc_0 "echo '. "\$HOME/.asdf/completions/asdf.bash"' >> ~/.bashrc"

echo "############### install terraform with asdf ###############"
exec_cmd_rc_0 "asdf plugin add terraform"
exec_cmd_rc_0 "asdf list all terraform"
exec_cmd_rc_0 "asdf install terraform latest"
exec_cmd_rc_0 "asdf list terraform"
exec_cmd_rc_0 "asdf global terraform latest"
exec_cmd_rc_0 "asdf list terraform"
exec_cmd_rc_0 "sh -c 'terraform version'"

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
# exec_cmd_rc_0 "sudo apt install -y build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev curl git libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev"
# 
# echo "############### install python 3.13:latest ###############"
# exec_cmd_rc_0 "pyenv install -l"
# exec_cmd_rc_0 "pyenv install 3.13"
# exec_cmd_rc_0 "pyenv versions"
# exec_cmd_rc_0 "pyenv global 3.13"
# exec_cmd_rc_0 "pyenv versions"

echo "############### install python with asdf ###############"
exec_cmd_rc_0 "asdf plugin add python"
exec_cmd_rc_0 "asdf list all python"
exec_cmd_rc_0 "sudo apt install -y build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev curl git libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev"
exec_cmd_rc_0 "asdf install python latest"
exec_cmd_rc_0 "asdf list python"
exec_cmd_rc_0 "asdf global python latest"
exec_cmd_rc_0 "asdf list python"
exec_cmd_rc_0 "sh -c 'python --version'"

sudo shutdown -r now
