configSamba(){
    if ! command -v smbstatus &> /dev/null
    then
        echo "Samba belum terinstal. Memulai proses instalasi...."
        sudo yum install -y samba
        sudo systemctl start smb
        sudo systemctl enable smb
        
        if [ $? -eq 0 ]; then
            echo "Samba berhasil diinstal."
        else
            echo "Gagal menginstal Samba periksa koneksi."
            exit 1
        fi
    else
        samba_version=$(smbstatus -V | awk 'NR==1{print $2}')
        echo "Samba sudah terinstal. Versi: $samba_version"
    fi

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
            echo "Konfigurasi samba sudah sesuai."
        else
            cp "$smb_conf" "$smb_conf.bak"
            echo "$desired_config" > "$smb_conf"
            echo "Konfigurasi telah diubah agar sama persis."
        fi
    else
        echo "File $smb_conf tidak ditemukan."
    fi
}

configSamba
