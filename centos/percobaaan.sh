prompt_domain_config() {
    echo "Please enter your domain (e.g., BCAFWIFI.CO.ID):"
    read DOMAIN

    echo "Please enter your domain controller (e.g., newDCWIFI01.bcafwifi.co.id):"
    read DOMAIN_CONTROLLER

    # Menghilangkan spasi saat melakukan assignment ke variabel
    DOMAIN_LOWERCASE=${DOMAIN,,}

    echo "Please enter your workgroup (e.g., BCAFWIFI):"
    read WORKGROUP
}


configure_kerberos() {
    echo "2. Configuring Kerberos..."
    # Menggunakan variabel DOMAIN_LOWERCASE yang telah dikonversi ke lowercase
    cat <<EOF | sudo tee /etc/krb5.conf
[logging]
 default = FILE:/var/log/krb5libs.log

[libdefaults]
 default_realm = ${DOMAIN^^}  # Mengkonversi DOMAIN ke uppercase
 dns_lookup_realm = false
 dns_lookup_kdc = false
 ticket_lifetime = 24h
 renew_lifetime = 7d
 forwardable = true

[realms]
 ${DOMAIN^^} = {
  kdc = $DOMAIN_CONTROLLER
  admin_server = $DOMAIN_CONTROLLER
 }

[domain_realm]
 .$DOMAIN_LOWERCASE = ${DOMAIN^^}
 $DOMAIN_LOWERCASE = ${DOMAIN^^}
EOF
    if [ $? -eq 0 ]; then
        echo "2. Successfully configured Kerberos. == PASS" >> "$report_file"
        ((SUCCESS_COUNT++))
    else
        echo "2. Failed to configure Kerberos. == FAIL" >> "$report_file"
        ((FAILURE_COUNT++))
        exit 1
    fi
}

# Memanggil fungsi prompt_domain_config terlebih dahulu untuk mendapatkan input
prompt_domain_config
# Kemudian memanggil configure_kerberos untuk mengkonfigurasi kerberos dengan variabel yang telah didefinisikan
configure_kerberos
