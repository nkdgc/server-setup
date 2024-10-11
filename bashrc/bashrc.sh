alias ll='ls -l'
set -o vi
export EDITOR=vim

# --- PS1 ---
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

# --- Kubernetes ---
# source <(tanzu completion bash)
# source <(kubectl completion bash)
alias k=kubectl
# source <(kubectl completion bash | sed -e 's/kubectl/k/g')

if [ -e /home/vmware/.kube-ps1.sh ]; then
  source /home/vmware/.kube-ps1.sh
  PS1='$(kube_ps1)'
  PS1="${PS1} ${PS1_COLOR}\u@\h [ ${NORMAL}\w${PS1_COLOR} ] \\$ ${NORMAL}"
fi

alias kx=kubectx
alias kn=kubens
alias k='kubecolor'
