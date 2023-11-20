#!/bin/bash

session="PORTAL"
cd /home/coder/cloud-hub
tmux new-session -d -s ${session}

# 0: DB (migrate$B$,Av$kA0$O(BDB$B$,B8:_$7$J$$$N$G(B60$BIC(Bsleep$B$9$k!K(B
page=0
tmux rename-window -t ${session}:${page} "DB"
tmux send-keys -t ${session}:${page} "echo '\pset pager off' > ~/.psqlrc" Enter
tmux send-keys -t ${session}:${page} "sleep 60; PGPASSWORD=password psql -U postgres -h cloudhub-db -l; PGPASSWORD=password psql -U postgres -h cloudhub-db -d vcenter_vm" Enter

# 1: FE
page=1
tmux new-window -t ${session}
tmux rename-window -t ${session}:${page} "FE"
tmux send-keys -t ${session}:${page} "cd /home/coder/cloud-hub/fe" Enter
tmux send-keys -t ${session}:${page} "npm install" Enter
tmux send-keys -t ${session}:${page} "ng build" Enter
tmux send-keys -t ${session}:${page} "sudo npm install -g http-server" Enter
tmux send-keys -t ${session}:${page} "http-server ./dist/fe --port 4200" Enter
# tmux send-keys -t ${session}:${page} "ng serve --host=0.0.0.0" Enter

# 2:BFF
page=2
tmux new-window -t ${session}
tmux rename-window -t ${session}:${page} "BFF"
tmux send-keys -t ${session}:${page} "cd /home/coder/cloud-hub/bff/bff" Enter
tmux send-keys -t ${session}:${page} "poetry install" Enter
tmux send-keys -t ${session}:${page} "poetry run python3 -m uvicorn main:app --reload --port 8010 --host=0.0.0.0" Enter

# 3: BE-PortalAuth
page=3
tmux new-window -t ${session}
tmux rename-window -t ${session}:${page} "BE-PortalAuth"
tmux send-keys -t ${session}:${page} "cd /home/coder/cloud-hub/be/portal_auth" Enter
tmux send-keys -t ${session}:${page} "poetry install" Enter
tmux send-keys -t ${session}:${page} "export EXPIRES_MINUTES=10" Enter
tmux send-keys -t ${session}:${page} "poetry run python3 -m uvicorn app.main:app --reload --port 8011 --host=0.0.0.0" Enter

# 4-1: BE-PortalAuth seed
page=4
tmux new-window -t ${session}
tmux send-keys -t ${session}:${page} "cd /home/coder/cloud-hub/be/portal_auth" Enter
tmux send-keys -t ${session}:${page} "poetry run python3 -m seed.seed" Enter

# 4-2: BE-vCenterVM
tmux rename-window -t ${session}:${page} "BE-vCenterVM"
tmux send-keys -t ${session}:${page} "cd /home/coder/cloud-hub/be/vcenter_vm" Enter
tmux send-keys -t ${session}:${page} "poetry install" Enter
tmux send-keys -t ${session}:${page} "export VCENTER_HOST=vcsa8.home.ndeguchi.com" Enter
tmux send-keys -t ${session}:${page} "export VCENTER_USER=administrator@vsphere.local" Enter
tmux send-keys -t ${session}:${page} "export VCENTER_PWD=VMware1!" Enter
tmux send-keys -t ${session}:${page} "export VCENTER_CONSOLE_USER=console_user" Enter
tmux send-keys -t ${session}:${page} "export VCENTER_CONSOLE_PWD=console_password" Enter
tmux send-keys -t ${session}:${page} "export VCENTER_NAME=vcsa8" Enter
tmux send-keys -t ${session}:${page} "poetry run pip install -r requirements.txt" Enter
tmux send-keys -t ${session}:${page} "poetry run python3 -m uvicorn app.main:app --reload --port 8012 --host=0.0.0.0" Enter

# 5: BE-Inventory
page=5
tmux new-window -t ${session}
tmux rename-window -t ${session}:${page} "BE-Inventory"
tmux send-keys -t ${session}:${page} "cd /home/coder/cloud-hub/be/inventory" Enter
tmux send-keys -t ${session}:${page} "poetry install" Enter
tmux send-keys -t ${session}:${page} "poetry run python3 -m uvicorn app.main:app --reload --port 8013 --host=0.0.0.0" Enter

# 6: BE-Notice
page=6
tmux new-window -t ${session}
tmux rename-window -t ${session}:${page} "BE-Notice"
tmux send-keys -t ${session}:${page} "cd /home/coder/cloud-hub/be/notice" Enter
tmux send-keys -t ${session}:${page} "poetry install" Enter
tmux send-keys -t ${session}:${page} "poetry run python3 -m uvicorn app.main:app --reload --port 8014 --host=0.0.0.0" Enter

# 7: BE-History
page=7
tmux new-window -t ${session}
tmux rename-window -t ${session}:${page} "BE-History"
tmux send-keys -t ${session}:${page} "cd /home/coder/cloud-hub/be/history" Enter
tmux send-keys -t ${session}:${page} "poetry install" Enter
tmux send-keys -t ${session}:${page} "poetry run python3 -m uvicorn app.main:app --reload --port 8015 --host=0.0.0.0" Enter

# 8: git
page=8
tmux new-window -t ${session}
tmux rename-window -t ${session}:${page} "git"

# attach
tmux a -t ${session}

