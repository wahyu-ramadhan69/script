sssd_config_file="/etc/sssd/sssd.conf"

function setSssdPermissions() {
    chown root:root "$sssd_config_file"
    chmod 600 "$sssd_config_file"

    if [ $? -eq 0 ]; then
        echo "Permissions set successfully."
    else
        echo "Error: Failed to set permissions for SSSD configuration file."
    fi
}

setSssdPermissions