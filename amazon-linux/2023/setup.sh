#!/bin/bash

NON_ROOT_USERNAME="ec2-user"
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
exec_cmd_rc_0 "sudo dnf upgrade -y"
exec_cmd_rc_0 "sudo dnf install -y vim git traceroute tmux net-tools unzip"

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

exec_cmd_rc_0 "sudo dnf install -y docker"
exec_cmd_rc_0 "sudo systemctl start docker"
exec_cmd_rc_0 "sudo systemctl enable docker"
exec_cmd_rc_0 "sudo systemctl status docker --no-pager"
exec_cmd_rc_0 "sudo usermod -aG docker ${NON_ROOT_USERNAME}"
exec_cmd_rc_0 "sudo docker --version"   # Check

echo "############### install asdf ###############"
exec_cmd_rc_0 "git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.14.1"
exec_cmd_rc_0 "echo '. "\$HOME/.asdf/asdf.sh"' >> ~/.bashrc"
exec_cmd_rc_0 '. "$HOME/.asdf/asdf.sh"'
exec_cmd_rc_0 "echo '. "\$HOME/.asdf/completions/asdf.bash"' >> ~/.bashrc"

echo "############### install terraform with asdf ###############"
exec_cmd_rc_0 "asdf plugin add terraform"
exec_cmd_rc_0 "asdf list all terraform"
exec_cmd_rc_0 "sudo dnf install -y --allowerasing gnupg2"
exec_cmd_rc_0 "asdf install terraform latest"
exec_cmd_rc_0 "asdf list terraform"
exec_cmd_rc_0 "asdf global terraform latest"
exec_cmd_rc_0 "asdf list terraform"
exec_cmd_rc_0 "sh -c 'terraform version'"

echo "############### install python with asdf ###############"
exec_cmd_rc_0 "asdf plugin add python"
exec_cmd_rc_0 "asdf list all python"
exec_cmd_rc_0 "sudo dnf install -y gcc make patch zlib-devel bzip2 bzip2-devel readline-devel sqlite-devel openssl-devel tk-devel libffi-devel xz-devel"
exec_cmd_rc_0 "asdf install python latest"
exec_cmd_rc_0 "asdf list python"
exec_cmd_rc_0 "asdf global python latest"
exec_cmd_rc_0 "asdf list python"
exec_cmd_rc_0 "sh -c 'python --version'"

sudo shutdown -r now
