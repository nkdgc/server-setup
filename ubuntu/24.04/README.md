```bash
sudo su - ubuntu -c "wget https://raw.githubusercontent.com/nkdgc/server-setup/main/ubuntu/24.04/setup.sh && chmod 755 setup.sh && ./setup.sh <HOSTNAME> |& tee setup.sh.log"

# silent
sudo su - ubuntu -c "wget https://raw.githubusercontent.com/nkdgc/server-setup/main/ubuntu/24.04/setup.sh && chmod 755 setup.sh && ./setup.sh <HOSTNAME> --silent |& tee setup.sh.log"
```
