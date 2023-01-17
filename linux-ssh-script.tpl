cat <<EOF>> ~/.ssh/config
Host ${hostname}
    hostname ${hostname}
    User ${user}
    IdentityFile ${identityfile}
EOF