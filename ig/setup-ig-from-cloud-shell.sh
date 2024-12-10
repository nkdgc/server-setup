#!/bin/bash

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

echo "############### install asdf ###############"
exec_cmd_rc_0 "sudo dnf swap gnupg2-minimal gnupg2-full"
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
