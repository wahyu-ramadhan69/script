update_chrony_config() {
    cp /etc/chrony.conf /etc/chrony.conf.bak

    sed -i 's/^server 0.centos.pool.ntp.org iburst/#&/' /etc/chrony.conf
    sed -i 's/^server 1.centos.pool.ntp.org iburst/#&/' /etc/chrony.conf
    sed -i 's/^server 2.centos.pool.ntp.org iburst/#&/' /etc/chrony.conf
    sed -i 's/^server 3.centos.pool.ntp.org iburst/#&/' /etc/chrony.conf

    # Add new NTP server configurations
    echo "server 10.4.198.15" >> /etc/chrony.conf
    echo "server 10.20.198.15" >> /etc/chrony.conf

    # Restart chronyd service to apply changes
    systemctl restart chronyd

    # Check if the configuration has been successfully updated
    if [ $? -eq 0 ]; then
        echo "Chrony configuration updated successfully."
    else
        echo "Failed to update Chrony configuration."
        # Restore the original configuration
        mv /etc/chrony.conf.bak /etc/chrony.conf
        systemctl restart chronyd
    fi
}

update_chrony_config