#!/bin/bash

report_file="tes.txt"

if [ "$EUID" -ne 0 ]; then
  echo "Script harus dijalankan sebagai root. Gunakan sudo atau login sebagai root."
  exit 1
fi

# Mengumpulkan informasi sistem
hostname=$(hostname)
date_now=$(date)
ip_address=$(hostname -I)
SUCCESS_COUNT=0
FAILURE_COUNT=0

CURRENT_DATE=$(date +"%Y-%m-%d %H:%M:%S")
HOSTNAME=$(hostname)
ip_address=$(hostname -I | awk '{print $1}')
os_info=$(cat /etc/redhat-release)
domain=$(hostname -d)
logged_users=$(who | awk '{print $1}' | sort | uniq)

echo "============ Laporan hasil join domain ======================" >> "$report_file"
echo "Waktu Pengecheckan: $CURRENT_DATE" >> "$report_file"
echo "Host: $HOSTNAME" >> "$report_file"
echo "IP Address: $ip_address" >> "$report_file"
echo "OS Information: $os_info" >> "$report_file"
echo "Domain: $domain" >> "$report_file"
echo "Logged Users: $logged_users" >> "$report_file"
echo "==============================================================" >> "$report_file"

# Meminta input konfigurasi domain

prompt_domain_config() {
    echo "Please enter your domain (e.g., BCAFWIFI.CO.ID):"
    read DOMAIN

    echo "Please enter your domain controller (e.g., newDCWIFI01.bcafwifi.co.id):"
    read DOMAIN_CONTROLLER

    DOMAIN_LOWERCASE=${DOMAIN,,}

    echo "Please enter your workgroup (e.g., BCAFWIFI):"
    read WORKGROUP
}

# Instalasi expect
install_expect() {
    echo "Installing expect..."
    sudo dnf install -y expect
    if [ $? -eq 0 ]; then
        echo "Successfully installed expect."
    else
        echo "Failed to install expect."
        exit 1
    fi
}   

prompt_credentials() {
    echo "Please enter the admin username for domain join:"
    read ADMIN_USER

    echo "Please enter the password for $ADMIN_USER:"
    read -s ADMIN_PASSWORD
}

# Fungsi untuk melakukan kinit dengan expect
perform_kinit() {
    /usr/bin/expect <<EOF
spawn kinit $ADMIN_USER
expect "Password for $ADMIN_USER:"
send "$ADMIN_PASSWORD\r"
expect eof
EOF
    if [ $? -eq 0 ]; then
        echo "Authentication successful."
    else
        echo "Authentication failed."
        exit 1
    fi
}

# Instalasi paket yang diperlukan
install_packages() {
    echo "1. Installing necessary packages..."
    sudo dnf install -y krb5-workstation krb5-server krb5-libs samba samba-common oddjob oddjob-mkhomedir sssd chrony
    if [ $? -eq 0 ]; then
        echo "1. Successfully installed necessary packages. == PASS" >> "$report_file"
        ((SUCCESS_COUNT++))
    else
        echo "1. Failed to install necessary packages. == FAIL" >> "$report_file"
        ((FAILURE_COUNT++))
        exit 1
    fi
}

# Konfigurasi Kerberos
configure_kerberos() {
    echo "2. Configuring Kerberos..."
    cat <<EOF | sudo tee /etc/krb5.conf
[logging]
 default = FILE:/var/log/krb5libs.log

[libdefaults]
 default_realm = $DOMAIN
 dns_lookup_realm = false
 dns_lookup_kdc = false
 ticket_lifetime = 24h
 renew_lifetime = 7d
 forwardable = true

[realms]
 $DOMAIN = {
  kdc = $DOMAIN_CONTROLLER
  admin_server = $DOMAIN_CONTROLLER
 }

[domain_realm]
 .$DOMAIN_LOWERCASE = $DOMAIN
 $DOMAIN_LOWERCASE = $DOMAIN
EOF
    if [ $? -eq 0 ]; then
        echo "2. Successfully configured Kerberos. == PASS" >> "$report_file"
        ((SUCCESS_COUNT++))
    else
        echo "2. Failed to configure Kerberos. FAIL" >> "$report_file"
        ((FAILURE_COUNT++))
        exit 1
    fi
}

# Konfigurasi Samba
configure_samba() {
    echo "3. Configuring Samba..."
    cat <<EOF | sudo tee /etc/samba/smb.conf
[global]
   workgroup = $WORKGROUP
   client signing = yes
   client use spnego = yes
   kerberos method = secrets and keytab
   realm = $DOMAIN
   security = ads
EOF
    if [ $? -eq 0 ]; then
        echo "3. Successfully configured Samba. == PASS" >> "$report_file"
        ((SUCCESS_COUNT++))
    else
        echo "3. Failed to configure Samba. == FAIL" >> "$report_file"
        ((FAILURE_COUNT++))
        exit 1
    fi
}

# Konfigurasi Chrony
configure_chrony() {
    echo "4. Configuring Chrony..."

    grep 'nameserver' /etc/resolv.conf | awk '{print $2}' | while read -r dns_server; do
        echo "Menambahkan DNS server $dns_server ke /etc/chrony.conf"
        echo "server $dns_server" | sudo tee -a /etc/chrony.conf > /dev/null
    done

    sudo systemctl restart chronyd
    if [ $? -eq 0 ]; then
        echo "4. Layanan chronyd berhasil direstart dan konfigurasi DNS telah diterapkan. == PASS"
        ((SUCCESS_COUNT++))
    else
        echo "4. Terjadi kesalahan saat merestart layanan chronyd. Silakan periksa log sistem untuk detailnya. == PASS"
        ((FAILURE_COUNT++))
        exit 1
    fi
}

# Konfigurasi SSSD
configure_sssd() {
    echo "5. Configuring SSSD..."
    cat <<EOF | sudo tee /etc/sssd/sssd.conf
[sssd]
domains = $DOMAIN
config_file_version = 2
services = nss, pam

[domain/$DOMAIN]
ad_domain = $DOMAIN
krb5_realm = $DOMAIN
realmd_tags = manages-system joined-with-samba
cache_credentials = True
id_provider = ad
krb5_store_password_if_offline = True
default_shell = /bin/bash
ldap_id_mapping = True
use_fully_qualified_names = False
fallback_homedir = /home/%u@%d
access_provider = ad
EOF
    sudo chmod 600 /etc/sssd/sssd.conf
    if [ $? -eq 0 ]; then
        echo "5. Successfully configured SSSD. == PASS" >> "$report_file"
        ((SUCCESS_COUNT++))
    else
        echo "5. Failed to configure SSSD. == FAIL" >> "$report_file"
        ((FAILURE_COUNT++))
        exit 1
    fi
}

# Join domain
join_domain() {
    echo "6. Joining the domain..."
    perform_kinit
    sudo net ads join -k
    if [ $? -eq 0 ]; then
        echo "6. Successfully joined the domain. == PASS" >> "$report_file"
        ((SUCCESS_COUNT++))
        sudo systemctl start sssd
        sudo systemctl enable sssd
    else
        echo "6. Failed to join the domain. == FAIL" >> "$report_file"
        ((FAILURE_COUNT++))
        exit 1
    fi
}

# Konfigurasi PAM
configure_pam() {
    echo "7. Configuring PAM..."
    sudo authselect select sssd with-mkhomedir --force
    if [ $? -eq 0 ]; then
        echo "7. Successfully configured PAM. == PASS" >> "$report_file"
        ((SUCCESS_COUNT++))
    else
        echo "7. Failed to configure PAM. == FAIL" >> "$report_file"
        ((FAILURE_COUNT++))
        exit 1
    fi
}

# Main function to execute all steps
main() {
    prompt_domain_config
    install_expect
    prompt_credentials
    install_packages
    configure_kerberos
    configure_samba
    configure_chrony
    configure_sssd
    join_domain
    configure_pam
}

main

echo -e "Jumlah Perintah Berhasil: $SUCCESS_COUNT" >> "$report_file"
echo -e "Jumlah Perintah Gagal: $FAILURE_COUNT" >> "$report_file"
echo -e "\nLaporan disimpan dalam file: $report_file"
exit 0