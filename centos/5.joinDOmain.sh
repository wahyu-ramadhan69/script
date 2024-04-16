function installSssd() {
    yum -y install sssd

    if [ $? -eq 0 ]; then
        echo "SSSD installation successful."
        return 0
    else
        echo "Error: SSSD installation failed."
        return 1
    fi
}


sssd_config_file="/etc/sssd/sssd.conf"

sssd_config_data="[sssd]
domains = bcafwifi.co.id
config_file_version = 2
services = nss, pam

[domain/bcafwifi.co.id]
ad_domain = bcafwifi.co.id
krb5_realm = BCAFWIFI.CO.ID
realmd_tags = manages-system joined-with-samba
cache_credentials = True
id_provider = ad
krb5_store_password_if_offline = True
default_shell = /bin/bash
ldap_id_mapping = True
use_fully_qualified_names = True
fallback_homedir = /home/%d/%u
access_provider = simple
simple_allow_users = bcafmaster
"

function createSssdConfig() {
    echo "Creating SSSD configuration file..."
    echo "$sssd_config_data" > "$sssd_config_file"
    
    if [ $? -eq 0 ]; then
        echo "SSSD configuration file created successfully."
    else
        echo "Error: Failed to create SSSD configuration file."
    fi
}

installSssd
createSssdConfig