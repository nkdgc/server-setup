#!/bin/bash

NON_ROOT_USERNAME="vmware"

SSH_AUTHORIZED_KEY="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC2xdFy6t0tncxWcgzBnrlOXjmbmTaEVdIrrKlLG0nQzCJOu6Jabs2tyKeNMuUuBBtL59yuQQfTAWZNcitVRxMX15rZ9CZKNQLr9lZ8w/ODWEpjfGjeQotT9YasAfgqEwc0aJ/QZZe9ZIQHgspszgP8wCTakjXKW0kxie/CtpIEk0l/BLybIegviptXxdPIneozZEt9RHALe3W2+zy0YDRoMUjopyxbtIjssVBMgPfCeROINfSecPkYwK0ig4Wa1bc6XCMklyeLWdmag5r8JQTPPZHVrk76z1UOGF9AFAmbjPVh+uRlKr49CMF3Balg1/DI5mUG6H5AEB75uV8rj1w+xUcU67w9vftpwUk2ohqsBRHtstlCmxN+uqcWOVQPzjSPx42w48nkzlqyZEx8FtIx1ENJRnTwzkfAeKg5UxfXRSDl2Ryh165lfWtLxMMZphegqxFhSLwJIMeXVBDzQT2e6BNELUU/B88VD15mxMx6S3GMuVdbrLG+WQULSq4mUkM="

if [ "$(whoami)" != "root" ]; then
    echo "You're not a root user."
    exit 1
fi

echo "--- Disable password expiration"
passwd -x -1 root

echo "--- Create user ${NON_ROOT_USERNAME}"
useradd -m -G sudo,docker ${NON_ROOT_USERNAME}
passwd ${NON_ROOT_USERNAME}
passwd -x -1 ${NON_ROOT_USERNAME}

echo "--- Set aliases"
cat <<EOF > /etc/profile.d/aliases.sh
alias ll='ls -l'
set -o vi
EOF
chmod 644 /etc/profile.d/aliases.sh

echo "--- create ssh key (root)"
ssh-keygen -t rsa -N "" -f /root/.ssh/id_rsa

echo "--- create ssh key (${NON_ROOT_USERNAME})"
su - ${NON_ROOT_USERNAME} -c "ssh-keygen -t rsa -N \"\" -f /home/${NON_ROOT_USERNAME}/.ssh/id_rsa"

echo "--- add authorized key"
echo ${SSH_AUTHORIZED_KEY} >> /root/.ssh/authorized_keys
echo ${SSH_AUTHORIZED_KEY} >> /home/${NON_ROOT_USERNAME}/.ssh/authorized_keys
chown ${NON_ROOT_USERNAME}:users /home/${NON_ROOT_USERNAME}/.ssh/authorized_keys
chmod 600 /home/${NON_ROOT_USERNAME}/.ssh/authorized_keys

echo "--- tdnf install vim/less/diff.."
tdnf install -y vim less diffutils tar tmux tcpdump bindutils traceroute curl wget lsof
# difutils for diff
# bindutils for dig

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
chown ${NON_ROOT_USERNAME}:users /home/${NON_ROOT_USERNAME}/.vimrc

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
EOF

echo "--- create .tmux.conf (${NON_ROOT_USERNAME})"
cp /root/.tmux.conf /home/${NON_ROOT_USERNAME}/.tmux.conf
chown ${NON_ROOT_USERNAME}:users /home/${NON_ROOT_USERNAME}/.tmux.conf

echo "--- create network file template"

cat <<EOF > /root/99-static.network
[Match]
Name=eth0

[Network]
Address=x.x.x.x/y
Gateway=z.z.z.z

# [Route]
# Gateway=x.x.x.x/y
# Destination=z.z.z.z
# 
# [Route]
# Gateway=x.x.x.x/y
# Destination=z.z.z.z

# /etc/systemd/network/
# systemctl restart systemd-networkd
EOF

chmod 644 /root/99-static.network

echo "--- set PS1"
cat << 'EOF' >> /etc/profile
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

echo "--- set timezone"
timedatectl set-timezone Asia/Tokyo

echo "--- disable iptables"
systemctl stop iptables
systemctl disable iptables

