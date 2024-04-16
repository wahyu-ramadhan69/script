#!/bin/bash

if rpm -q krb5-workstation &> /dev/null; then
    echo "krb5-workstation sudah terinstal. Versi: $(rpm -q krb5-workstation)"
else
    echo "krb5-workstation belum terinstal. Melakukan instalasi..."
    sudo yum install -y krb5-workstation
    if [ $? -eq 0 ]; then
        echo "Instalasi karberos berhasil."
    else
        echo "Instalasi karberos gagal. Terdapat kesalahan."
    fi
fi