#!/bin/bash

NON_ROOT_USERNAME="ubuntu"
SSH_AUTHORIZED_KEY="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDZNC5l+WdfpXySw53YR7t6VQ3yfwfw5N1NV6i+YICYSw738iL5pFha7bKQ4wvTF8v1YRzbE8Ss2NMNrDgMj5fyxadW+GTzd9Jf9FmuMP+Yf+yao2pmsfNr28Bp5JMvcwUlrhpwTs0nHe724+EN4j/GwS3gGcmPD+4NDzYYWDJeDOU+ufniwV98KOdWZ296FCFGS+aiQMMQ8DsfOY5RdkaF6DrE69spn8qi5B5kDVzk3+XkQpv67ovJY9/1EOLlcfoash4EKARZtoilSt+hA3XpybFgBQXlf+fGPqJZ48kDT+2hC3/bX4KXSp54mg9bf2OwHrrBGSe3+tEeXdZph4jfTB/hdFaA0JRiyRj0ncvqR+CPzayHy9os9tj2ekwpC3XRGrHqcgJoVWK/Ok8qRIHnJomE2uHCMZreL6rhc3BGxO2zgWH7wp5RB+jGxFQV4VznYEeeyciKvX4GMtOysjkC0LmfzcGL3nAaJ4k6m5nVO6ytDqZZEiLQlMJH1tBgesU= ndeguchi@c889f3de2f50"

# Check if the script is running as the root user
if [ "$(whoami)" != "root" ]; then
    echo "Error: This script must be run as the root user. Please run the script with 'sudo' or as the root user."
    exit 1
fi

# Check the number of arguments
if [ "$#" -ne 1 ]; then
  echo "Error: This script requires exactly one argument (the hostname)."
  echo "Usage: $0 <hostname>"
  exit 1
fi

# Confirm and change the hostname
echo "--- change hostname"
hostname="$1"
read -p "Change the hostname to ${hostname}? (Y/n): " confirm
case "$confirm" in
  [yY]*)
    echo "Changing hostname to $hostname..."
    hostnamectl set-hostname "${hostname}"
    ;;
  *)
    echo "Exiting script."
    exit 0
    ;;
esac

# echo "--- set root password"
# passwd

echo "--- Set aliases"
cat <<EOF >> /root/.bashrc
alias ll='ls -l'
set -o vi
export EDITOR=vim
# source <(tanzu completion bash)
# source <(kubectl completion bash)
alias k=kubectl
# source <(kubectl completion bash | sed -e 's/kubectl/k/g')
EOF

cat <<EOF >> /home/${NON_ROOT_USERNAME}/.bashrc
alias ll='ls -l'
set -o vi
# source <(tanzu completion bash)
# source <(kubectl completion bash)
alias k=kubectl
# source <(kubectl completion bash | sed -e 's/kubectl/k/g')
EOF


echo "--- create ssh key"
# ssh-keygen -t rsa -N "" -f /root/.ssh/id_rsa
su - ${NON_ROOT_USERNAME} -c "ssh-keygen -t rsa -N '' -f /home/${NON_ROOT_USERNAME}/.ssh/id_rsa"

echo "--- add authorized key"
# echo ${SSH_AUTHORIZED_KEY} >> /root/.ssh/authorized_keys
echo ${SSH_AUTHORIZED_KEY} >> /home/${NON_ROOT_USERNAME}/.ssh/authorized_keys

# echo "--- change apt repository to ftp.riken.jp"
# perl -p -i.bak -e 's%(deb(?:-src|)\s+)https?://(?!archive\.canonical\.com|security\.ubuntu\.com)[^\s]+%$1http://ftp.riken.jp/Linux/ubuntu/%' /etc/apt/sources.list

echo "--- apt update"
apt update

echo "--- apt upgrade"
apt upgrade -y

echo "--- apt install vim/git/openssh-server/tmux/..."
apt install -y vim git openssh-server traceroute tmux vino dconf-editor curl net-tools

# echo "--- allow ssh root login"
# SSH_BASE_DIR="/etc/ssh"
# cat ${SSH_BASE_DIR}/sshd_config | sed -e "s/^#PermitRootLogin.*$/PermitRootLogin yes/g" > ${SSH_BASE_DIR}/sshd_config.mod
# mv ${SSH_BASE_DIR}/sshd_config.mod ${SSH_BASE_DIR}/sshd_config
# 
# systemctl restart sshd

echo "--- create .vimrc (root)"

cat <<EOF > /root/.vimrc
set nocompatible
set number
set tabstop=2
set showmatch
set incsearch
set hlsearch
set nowrapscan
set ignorecase
set fileencodings=utf-8,utf-16le,cp932,iso-2022-jp,euc-jp,default,latin
set foldmethod=marker
set nf=""
nnoremap <ESC><ESC> :nohlsearch<CR>
set laststatus=2
set statusline=%t%m%r%h%w\%=[POS=%p%%/%LLINES]\[TYPE=%Y][FORMAT=%{&ff}]\%{'[ENC='.(&fenc!=''?&fenc:&enc).']'}
syntax enable
set directory=/tmp
set backupdir=/tmp
set undodir=/tmp
set paste
EOF

echo "--- create .vimrc (${NON_ROOT_USERNAME})"
cp /root/.vimrc /home/${NON_ROOT_USERNAME}/.vimrc
chown ${NON_ROOT_USERNAME}:${NON_ROOT_USERNAME} /home/${NON_ROOT_USERNAME}/.vimrc

echo "--- create .tmux.conf (root)"

cat <<EOF > /root/.tmux.conf
set -g prefix C-q
unbind C-b
bind h select-pane -L
bind j select-pane -D
bind k select-pane -U
bind l select-pane -R
setw -g mode-keys vi
bind -T copy-mode-vi v send -X begin-selection
bind | split-window -h
bind - split-window -v
bind -r H resize-pane -L 1
bind -r J resize-pane -D 1
bind -r K resize-pane -U 1
bind -r L resize-pane -R 1
bind B setw synchronize-panes on
bind b setw synchronize-panes off
EOF

echo "--- create .tmux.conf (${NON_ROOT_USERNAME})"
cp /root/.tmux.conf /home/${NON_ROOT_USERNAME}/.tmux.conf
chown ${NON_ROOT_USERNAME}:${NON_ROOT_USERNAME} /home/${NON_ROOT_USERNAME}/.tmux.conf


# echo "--- install asciinema"
# apt-add-repository -y ppa:zanchey/asciinema
# apt-get update
# apt-get install -y asciinema



# echo "--- create network file template"
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

echo "--- set PS1"
cat << 'EOF' >> /root/.bashrc
NORMAL="\[\e[0m\]"
RED="\[\e[1;31m\]"
GREEN="\[\e[1;32m\]"
if [[ $EUID == 0 ]] ; then
  # root user
  PS1_COLOR="${RED}"
else
  # non root user
  PS1_COLOR="${GREEN}"
fi
PS1="${PS1_COLOR}\u@\h [ ${NORMAL}\w${PS1_COLOR} ]\\$ ${NORMAL}"
EOF

cat << 'EOF' >> /home/${NON_ROOT_USERNAME}/.bashrc
NORMAL="\[\e[0m\]"
RED="\[\e[1;31m\]"
GREEN="\[\e[1;32m\]"
if [[ $EUID == 0 ]] ; then
  # root user
  PS1_COLOR="${RED}"
else
  # non root user
  PS1_COLOR="${GREEN}"
fi
PS1="${PS1_COLOR}\u@\h [ ${NORMAL}\w${PS1_COLOR} ]\\$ ${NORMAL}"

if [ -e /home/vmware/.kube-ps1.sh ]; then
  source /home/vmware/.kube-ps1.sh
  PS1='$(kube_ps1)'
  PS1="${PS1} ${PS1_COLOR}\u@\h [ ${NORMAL}\w${PS1_COLOR} ] \\$ ${NORMAL}"
fi

alias kx=kubectx
alias kn=kubens
alias k='kubecolor'
EOF

echo "--- install docker engine"
apt-get update

apt-get install \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
usermod -aG docker ${NON_ROOT_USERNAME}

shutdown -r now

