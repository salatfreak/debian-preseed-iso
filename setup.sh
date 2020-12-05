#!/bin/bash

# Unpack data archive
tar -xf /tmp/data.tar.gz

# Change SSH configuration
cp /etc/ssh/sshd_config{,.bak}
cat >> /etc/ssh/sshd_config <<END

# Restrict logins
PermitRootLogin no
AllowUsers user
END
