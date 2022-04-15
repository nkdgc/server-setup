#!/bin/bash

NON_ROOT_USERNAME="vmware"

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


