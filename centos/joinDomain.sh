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


####perintah 1 instalasi kaberos########

installKaberos() {
  yum -y install krb5-workstation

  if [ $? -eq 0 ]; then
    echo "1. Instalasi krb5-workstation berhasil. == PASS" >> "$report_file"
    ((SUCCESS_COUNT++))
  else
    echo "1. Gagal melakukan instalasi krb5-workstation. Silakan periksa koneksi internet atau konfigurasi repository. == FAIL" >> "$report_file"
    ((FAILURE_COUNT++))
    exit 1
  fi
}

installSamba(){
  if ! command -v smbstatus &> /dev/null
    then
        echo "Samba belum terinstal. Memulai proses instalasi...."
        sudo yum install -y samba
        sudo systemctl start smb
        sudo systemctl enable smb
        
        if [ $? -eq 0 ]; then
            echo "4. Samba berhasil diinstal." >> "$report_file"
            ((SUCCESS_COUNT++))
        else
            echo "4. Gagal menginstal Samba periksa koneksi." >> "$report_file"
            ((FAILURE_COUNT++))
        fi
  else
      samba_version=$(smbstatus -V | awk 'NR==1{print $2}')
      echo "4. Samba sudah terinstal. Versi: $samba_version == PASS" >> "$report_file"
      ((SUCCESS_COUNT++))
  fi
}


#####ubah /etc/krb5.conf##########
NEW_KRB5_CONF="# Configuration snippets may be placed in this directory as well
includedir /etc/krb5.conf.d/

includedir /var/lib/sss/pubconf/krb5.include.d/
[logging]
 default = FILE:/var/log/krb5libs.log
 kdc = FILE:/var/log/krb5kdc.log
 admin_server = FILE:/var/log/kadmind.log

[libdefaults]
 default_realm = BCAFWIFI.CO.ID
 dns_lookup_realm = true
 dns_lookup_kdc = true
 ticket_lifetime = 24h
 renew_lifetime = 7d
 forwardable = true
 default_keytab_name = FILE:/etc/krb5.keytab

[realms]
 BCAFWIFI.CO.ID = {
  kdc = newDCWIFI01.bcafwifi.co.id
  admin_server = newDCWIFI01.bcafwifi.co.id
}

[domain_realm]
 .bcafwifi.co.id = BCAFWIFI.CO.ID
 bcafwifi.co.id = BCAFWIFI.CO.ID"

ubahKrb5Conf(){
  cp /etc/krb5.conf /etc/krb5.conf.bak
  echo "$NEW_KRB5_CONF" > /etc/krb5.conf
  if [ $? -eq 0 ]; then
    echo "2. Ubah /etc/krb5.conf berhasil. == PASS" >> "$report_file"
    ((SUCCESS_COUNT++))
  else
    echo "2. Gagal melakukan perubahan pada /etc/krb5.conf == FAIL" >> "$report_file"
    ((FAILURE_COUNT++))
    exit 1
  fi
}

installChrony() {
  yum -y install chrony

  if [ $? -eq 0 ]; then
    echo "3. Instalasi chrony berhasil. == PASS" >> "$report_file"
    ((SUCCESS_COUNT++))
  else
    echo "3. Gagal melakukan instalasi chrony. Silakan periksa koneksi internet atau konfigurasi repository. == FAIL" >> "$report_file"
    ((FAILURE_COUNT++))
    exit 1
  fi
}
####### 3. Edit source time
update_chrony_config() {
    cp /etc/chrony.conf /etc/chrony.conf.bak

    sed -i 's/^server 0.centos.pool.ntp.org iburst/#&/' /etc/chrony.conf
    sed -i 's/^server 1.centos.pool.ntp.org iburst/#&/' /etc/chrony.conf
    sed -i 's/^server 2.centos.pool.ntp.org iburst/#&/' /etc/chrony.conf
    sed -i 's/^server 3.centos.pool.ntp.org iburst/#&/' /etc/chrony.conf

    # Add new NTP server configurations
    echo "server 192.168.29.12" >> /etc/chrony.conf
    echo "server 192.168.29.101" >> /etc/chrony.conf

    # Restart chronyd service to apply changes
    # systemctl restart chronyd

    # Check if the configuration has been successfully updated
    if [ $? -eq 0 ]; then
        echo "3. Edit sources time success == PASS" >> "$report_file"
        ((SUCCESS_COUNT++))
    else
        echo "3. Edit sources time failed == FAIL" >> "$report_file"
        ((FAILURE_COUNT++))
        # Restore the original configuration
        mv /etc/chrony.conf.bak /etc/chrony.conf
        systemctl restart chronyd
    fi
}

##### 4. Edit config samba

configSamba(){
    smb_conf="/etc/samba/smb.conf"

    desired_config="[global]
   workgroup = BCAFWIFI
   client signing = yes
   client use spnego = yes
   kerberos method = secrets and keytab
   realm = BCAFWIFI.CO.ID
   security = ads"

    if [ -e "$smb_conf" ]; then
        if [ "$(cat "$smb_conf")" == "$desired_config" ]; then
            echo "4. Konfigurasi samba sudah sesuai. == PASS" >> "$report_file"
            ((SUCCESS_COUNT++))
        else
            cp "$smb_conf" "$smb_conf.bak"
            echo "$desired_config" > "$smb_conf"
            ((SUCCESS_COUNT++))
            echo "4. Konfigurasi telah diubah agar sama persis. == PASS" >> "$report_file"
        fi
    else
        echo "File $smb_conf tidak ditemukan. == FAIL" >> "$report_file"
        ((FAILURE_COUNT++))
    fi
}

##### 5. instalasi sssd dan config sssd

function installSssd() {
    yum -y install sssd

    if [ $? -eq 0 ]; then
        echo "5. SSSD Berhasil di install == PASS" >> "$report_file"
        ((SUCCESS_COUNT++))
        return 0
    else
        echo "5. SSSD Gagal di install periksa koneksi == FAIL" >> "$report_file"
        ((FAILURE_COUNT++))
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
        echo "5. Konfigurasi /etc/sssd/sssd.conf berhasil dilakukan == PASS" >> "$report_file"
        ((SUCCESS_COUNT++))
    else
        echo "5. Konfigurasi /etc/sssd/sssd.conf gagal dilakukan == FAIL" >> "$report_file"
        ((FAILURE_COUNT++))
    fi
}

###### 6. set permission /etc/sssd/sssd.conf

sssd_config_file="/etc/sssd/sssd.conf"

function setSssdPermissions() {
    chown root:root "$sssd_config_file"
    chmod 600 "$sssd_config_file"

    if [ $? -eq 0 ]; then
        echo "6. Set permissions /etc/sssd/sssd.conf berasil diperbaharui == PASS" >> "$report_file"
        ((SUCCESS_COUNT++))
    else
        echo "6. Set permission sssd.conf gagal diperbaharui == FAIL" >> "$report_file"
        ((FAILURE_COUNT++))
    fi
}

function rewrite_nsswitch() {
    local file="/etc/nsswitch.conf"
    local backup_file="${file}.backup"

    # Membuat cadangan file konfigurasi sebelum melakukan perubahan
    if [ ! -e "$backup_file" ]; then
        cp "$file" "$backup_file"
    else
        echo "File backup sudah ada."
    fi

    # Memeriksa keberadaan file nsswitch.conf sebelum memodifikasinya
    if [ -e "$file" ]; then
        # Menulis ulang file nsswitch.conf dengan konfigurasi yang ditentukan
        cat << EOF | tee "$file"
passwd:      compact sss
shadow:      files
group:       compact sss
hosts:       files dns myhostname
services:    files sss
netgroup:    nis sss
sudoers:     files sss
automount:   files sss

aliases:     files
ethers:      files
gshadow:     files

networks:    files dns
protocols:   files
publickey:   files
rpc:         files
EOF
        if [ $? -eq 0 ]; then
            echo "7. Berhasil memperbarui konfigurasi nsswitch.conf == PASS" >> "$report_file"
            ((FAILURE_COUNT++))
            return 0
        else
            echo "7. Gagal memperbarui konfigurasi nsswitch.conf == FAIL" >> "$report_file"
            ((FAILURE_COUNT++))
            return 1
        fi
    else
        echo "File $file tidak ditemukan."
        return 1
    fi
}

kinit_with_password() {
    user=$1
    password=$2
    timeout=30

    # Jalankan perintah kinit dengan user yang dimasukkan
    echo "$password" | sudo -S kinit $user

    # Periksa status keluar dari perintah kinit
    if [ $? -eq 0 ]; then
        echo "8. Berhasil melakukan kinit == PASS" >> "$report_file"
        ((SUCCESS_COUNT++))
    else
        echo "8. Gagal melakukan kinit atau timeout == FAIL" >> "$report_file"
        ((FAILURE_COUNT++))
    fi
}


add_hostname() {
    hostname=$1
    full_hostname="${hostname}.bcafwifi.co.id"
    sudo hostnamectl set-hostname $full_hostname
    echo "Hostname telah diubah menjadi $full_hostname"
}

function update_system_info {
  HOSTNAME=$(hostname)

  IP_ADDRESS=$(hostname -I | cut -d' ' -f1)

  DNS_INFO=$(cat /etc/resolv.conf | grep -E "^nameserver" | cut -d ' ' -f2)

  {
    echo "192.168.29.12 newDCWIFI101.bcafwifi.co.id" > /etc/hosts &&
    echo "192.168.29.103 NEWMPS.bcafwifi.co.id" >> /etc/hosts &&
    echo "$IP_ADDRESS $HOSTNAME" >> /etc/hosts
  } && {
    echo "8. Konfigurasi /etc/hosts berhasil diperbarui == PASS" >> "$report_file"
    ((SUCCESS_COUNT++))
  } || {
    echo "8. Kesalahan: Gagal memperbarui konfigurasi /etc/hosts == FAIL" >> "$report_file"
    ((FAILURE_COUNT++))
  }
}

joinDomain() {
    echo "Mencoba menggabungkan ke Active Directory..."
    sudo net ads join -k
    local status=$?

    if [ $status -eq 0 ]; then
        echo "8. Berhasil menggabungkan ke Active DOMAIN == PASS" >> "$report_file"
        ((SUCCESS_COUNT++))
    else
        echo "8. Gagal menggabungkan ke Active DOMAIN == FAIL" >> "$report_file"
        ((FAILURE_COUNT++))
        return $status
    fi
}

echo "Masukkan nama pengguna domain:"
read user

echo "Masukkan password domain:"
read -s password

echo "Masukkan hostname baru:"
read new_hostname

installKaberos
installSamba
ubahKrb5Conf
installChrony
update_chrony_config
configSamba
installSssd
createSssdConfig
setSssdPermissions
rewrite_nsswitch
kinit_with_password $user $password
add_hostname $new_hostname
update_system_info
joinDomain

echo -e "Jumlah Perintah Berhasil: $SUCCESS_COUNT" >> "$report_file"
echo -e "Jumlah Perintah Gagal: $FAILURE_COUNT" >> "$report_file"
echo -e "\nLaporan disimpan dalam file: $report_file"
exit 0
