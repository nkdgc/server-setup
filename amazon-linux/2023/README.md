```bash
sudo su - ec2-user -c "wget https://raw.githubusercontent.com/nkdgc/server-setup/refs/heads/main/amazon-linux/2023/setup.sh && chmod 755 setup.sh && ./setup.sh <HOSTNAME> |& tee setup.sh.log"

# Silent
sudo su - ec2-user -c "wget https://raw.githubusercontent.com/nkdgc/server-setup/refs/heads/main/amazon-linux/2023/setup.sh && chmod 755 setup.sh && ./setup.sh <HOSTNAME> --silent |& tee setup.sh.log"
```

