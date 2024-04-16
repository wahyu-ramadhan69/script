#!/bin/bash

OUTPUT_FILE="./hasil_check.txt"
CURRENT_DATE=$(date +"%Y-%m-%d %H:%M:%S")
HOSTNAME=$(hostname)
ip_address=$(hostname -I | awk '{print $1}')
os_info=$(cat /etc/redhat-release)
domain=$(hostname -d)
logged_users=$(who | awk '{print $1}' | sort | uniq)

echo "==============================================================" >> "$OUTPUT_FILE"
echo "Waktu Pengecheckan: $CURRENT_DATE" >> "$OUTPUT_FILE"
echo "Host: $HOSTNAME" >> "$OUTPUT_FILE"
echo "IP Address: $ip_address" >> "$OUTPUT_FILE"
echo "OS Information: $os_info" >> "$OUTPUT_FILE"
echo "Domain: $domain" >> "$OUTPUT_FILE"
echo "Logged Users: $logged_users" >> "$OUTPUT_FILE"
echo "==============================================================" >> "$OUTPUT_FILE"

#check 1
motd_path="/etc/motd"

if [ -f "$motd_path" ]; then
    motd_content=$(cat "$motd_path")

    target_string=$(cat <<'EOF'
WARNING (PERINGATAN) !!! All access to this computer is forbidden without authorization from BCAF's authorized personnel.
Violation to this will be prosecuted.This service is restricted to authorized users only.
All activities on this system are logged.
Unautorized access will be fully investigated and reported to the appropriate law enforcement agancies
EOF
)

    if [[ "$motd_content" == *"$target_string"* ]]; then
        echo "#Check 1. /etc/motd === Pass" >> "$OUTPUT_FILE"
    else
        echo "#Check 1. /etc/motd === Fail" >> "$OUTPUT_FILE"
    fi
else
    echo "#Check 1. File MOTD tidak ditemukan di $motd_path" >> "$OUTPUT_FILE"
fi

#check 2

issue_path="/etc/issue.net"

# Check if the MOTD file exists
if [ -f "$issue_path" ]; then
    motd_content=$(cat "$issue_path")

    target_string=$(cat <<'EOF'
WARNING (PERINGATAN) !!! All access to this computer is forbidden without authorization from BCAF's authorized personnel.
Violation to this will be prosecuted.This service is restricted to authorized users only.
All activities on this system are logged.
Unautorized access will be fully investigated and reported to the appropriate law enforcement agancies
EOF
)

    if [[ "$motd_content" == *"$target_string"* ]]; then
        echo "#Check 2. /etc/issue.net === Pass" >> "$OUTPUT_FILE"

    else
        echo "#Check 2. /etc/issue.net === Fail" >> "$OUTPUT_FILE"
    fi
else
    echo "#Check 2. File MOTD tidak ditemukan di $issue_path" >> "$OUTPUT_FILE"
fi


#Check 3.
ssh_config="/etc/ssh/sshd_config" 

# Mengecek apakah file konfigurasi SSH ada
if [ -f "$ssh_config" ]; then
    # Mengecek opsi-opsi tertentu dalam file konfigurasi SSH
    if
        grep -q "^X11Forwarding\s\+no" "$ssh_config" &&
        grep -q "^MaxAuthTries\s\+10" "$ssh_config" &&
        grep -q "^IgnoreRhosts\s\+yes" "$ssh_config" &&
        grep -q "^ClientAliveInterval\s\+300" "$ssh_config" &&
        grep -q "^ClientAliveCountMax\s\+0" "$ssh_config" &&
        grep -q "^PermitRootLogin\s\+no" "$ssh_config"; then
        echo "#Check 3. /etc/ssh/sshd_config == Pass" >> "$OUTPUT_FILE"
    else
        echo "#Check 3. /etc/ssh/sshd_config == Fail" >> "$OUTPUT_FILE"
    fi
else
    echo "#Check 3. File konfigurasi SSH tidak ditemukan di $ssh_config == Fail" >> "$OUTPUT_FILE"
fi

#Check 4
pwquality_config="/etc/security/pwquality.conf"

# Mengecek apakah file konfigurasi pwquality ada
if [ -f "$pwquality_config" ]; then
    if grep -q "^minlen\s*=\s*6" "$pwquality_config" &&
       grep -q "^dcredit\s*=\s*1" "$pwquality_config" &&
       grep -q "^ucredit\s*=\s*1" "$pwquality_config" &&
       grep -q "^lcredit\s*=\s*1" "$pwquality_config" &&
       grep -q "^usercheck\s*=\s*1" "$pwquality_config"; then
        echo "#Check 4. $pwquality_config == Pass" >> "$OUTPUT_FILE"
    else
        echo "#Check 4. $pwquality_config == Fail" >> "$OUTPUT_FILE"
    fi
else
    echo "#Check 4. File konfigurasi pwquality tidak ditemukan di $pwquality_config == Fail" >> "$OUTPUT_FILE"
fi

#Check 5.
password_auth_config="/etc/pam.d/password-auth"

# Mengecek apakah file konfigurasi password-auth ada
if [ -f "$password_auth_config" ]; then
    # Mengecek nilai tertentu dalam file konfigurasi password-auth
    if grep -q "^password    requisite     pam_pwquality.so try_first-pass local_users_only retry=10 remember=12 authtok_type=" "$password_auth_config"; then
        echo "#Check 5. $password_auth_config == Pass" >> "$OUTPUT_FILE"
    else
        echo "#Check 5. $password_auth_config == Fail" >> "$OUTPUT_FILE"
    fi
else
    echo "#Check 5. File konfigurasi password-auth tidak ditemukan di $password_auth_config == Fail" >> "$OUTPUT_FILE"
fi

#Check 6.
system_auth_config="/etc/pam.d/system-auth"

# Mengecek apakah file konfigurasi system-auth ada
if [ -f "$system_auth_config" ]; then
    # Mengecek nilai tertentu dalam file konfigurasi system-auth
    if grep -q "^password    requisite     pam_pwquality.so try_first-pass local_users_only retry=10 remember=12 authtok_type=" "$system_auth_config"; then
        echo "#Check 6. Check $system_auth_config == Pass" >> "$OUTPUT_FILE"
    else
        echo "#Check 6. $system_auth_config == Fail" >> "$OUTPUT_FILE"
    fi
else
    echo "#Check 6. File konfigurasi system-auth tidak ditemukan di $system_auth_config == Fail" >> "$OUTPUT_FILE"
fi

#Check 7.
login_defs_config="/etc/login.defs"

# Mengecek apakah file konfigurasi login.defs ada
if [ -f "$login_defs_config" ]; then
    # Mengecek nilai tertentu dalam file konfigurasi login.defs
    if grep -q "^PASS_MAX_DAYS\s*35" "$login_defs_config" &&
       grep -q "^PASS_MIN_DAYS\s*1" "$login_defs_config" &&
       grep -q "^PASS_WARN_AGE\s*14" "$login_defs_config"; then
        echo "#Check 7. $login_defs_config == Pass" >> "$OUTPUT_FILE"
    else
        echo "#Check 7. $login_defs_config == Fail" >> "$OUTPUT_FILE"
    fi
else
    echo "#Check 7 .File konfigurasi login.defs tidak ditemukan di $login_defs_config" >> "$OUTPUT_FILE"
fi

#Check 8
result=$(grep "^root:" /etc/passwd | cut -f4 -d:)

if [ "$result" -eq 0 ]; then
    echo "#Check 8. grep "^root:" /etc/passwd | cut -f4 -d: == Pass" >> "$OUTPUT_FILE"
else
    echo "#Check 8. grep "^root:" /etc/passwd | cut -f4 -d: == Fail" >> "$OUTPUT_FILE"
fi

#Check 9.
pam_su_config="/etc/pam.d/su"

# Mengecek apakah file konfigurasi su ada
if [ -f "$pam_su_config" ]; then
    # Mengecek apakah baris yang mengandung "auth required pam_wheel.so" sudah diuncomment
    if grep -qE '^[[:space:]]*auth[[:space:]]+required[[:space:]]+pam_wheel.so' "$pam_su_config"; then
        echo "#Check 9. $pam_su_config == Pass" >> "$OUTPUT_FILE"
    else
        echo "#Check 9. $pam_su_config == Fail" >> "$OUTPUT_FILE"
    fi
else
    echo "#Check 9. File konfigurasi su tidak ditemukan di $pam_su_config == Fail" >> "$OUTPUT_FILE"
fi

#Check 10.
service_name="konea"

# Memeriksa status layanan
if systemctl is-active --quiet "$service_name"; then
    echo "#Check 10. Intalasi Kace == Pass" >> "$OUTPUT_FILE"
else
    echo "#Check 10. Instalasi Kace == Fail" >> "$OUTPUT_FILE"
fi


#Check 11.
chrony_config="/etc/chrony.conf"
target_value="server wsadc1809001.bcaf.co.id"

if [ -f "$chrony_config" ]; then
    if grep -q "$target_value" "$chrony_config"; then
        echo "#Check 12. $chrony_config == Pass" >> "$OUTPUT_FILE"
    else
        echo "#Check 12. $chrony_config == Fail" >> "$OUTPUT_FILE"
    fi
else
    echo "#Check 12. File konfigurasi Chrony tidak ditemukan di $chrony_config == Fail" >> "$OUTPUT_FILE"
fi

#Check 12.
if systemctl is-active --quiet chronyd; then
    echo "#Check 12. Chrony == Pass" >> "$OUTPUT_FILE"
else
    echo "#Check 12. Chrony == Fail" >> "$OUTPUT_FILE"
fi

#Check 13.
audit_rules="/etc/audit/rules.d/audit.rules"

if [ -f "$audit_rules" ]; then
    # Mengecek nilai tertentu dalam file konfigurasi system-auth
    if grep -q "^-w /etc/group -p wa -k identity" "$audit_rules" &&
           grep -q "^-w /etc/passwd -p wa -k identity" "$audit_rules" &&
           grep -q "^-w /etc/shadow -p wa -k identity" "$audit_rules" &&
           grep -q "^-w /etc/gshadow -p wa -k identity" "$audit_rules" &&
           grep -q "^-w /etc/sudoers -p wa -k identity" "$audit_rules" &&
           grep -q "^-w /etc/security/opasswd -p wa -k identity" "$audit_rules" &&
           grep -q "^-a always,exit -F arch=b64 -S adjtimex -S settimeofday -k time-change" "$audit_rules" &&
           grep -q "^-a always,exit -F arch=b32 -S adjtimex -S settimeofday -S stime -k time-change" "$audit_rules" &&
           grep -q "^-a always,exit -F arch=b64 -S clock_settime -k time-change" "$audit_rules" &&
           grep -q "^-a always,exit -F arch=b32 -S clock_settime -k time-change" "$audit_rules" &&
           grep -q "^-w /etc/localtime -p wa -k time-change" "$audit_rules" &&
           grep -q "^-w /var/log/faillog -p wa -k logins" "$audit_rules" &&
           grep -q "^-w /var/log/lastlog -p wa -k logins" "$audit_rules" &&
           grep -q "^-w /var/log/tallylog -p wa -k logins" "$audit_rules" &&
           grep -q "^-a always,exit -F arch=b64 -S chmod -S fchmod -S fchmodat -F auid>=1000 -F auid!=4294967295 -k perm_mod" "$audit_rules" &&
           grep -q "^-a always,exit -F arch=b32 -S chmod -S fchmod -S fchmodat -F auid>=1000 -F auid!=4294967295 -k perm_mod" "$audit_rules" &&
           grep -q "^-a always,exit -F arch=b64 -S chown -S fchown -S fchownat -S lchown -F auid>=1000 -F auid!=4294967295 -k perm_mod" "$audit_rules" &&
           grep -q "^-a always,exit -F arch=b32 -S chown -S fchown -S fchownat -S lchown -F auid>=1000 -F auid!=4294967295 -k perm_mod" "$audit_rules" &&
           grep -q "^-a always,exit -F arch=b64 -S setxattr -S lsetxattr -S fsetxattr -S removexattr -S lremovexattr -S fremovexattr -F auid>=1000 -F auid!=4294967295 -k perm_mod" "$audit_rules" &&
           grep -q "^-a always,exit -F arch=b32 -S setxattr -S lsetxattr -S fsetxattr -S removexattr -S lremovexattr -S fremovexattr -F auid>=1000 -F auid!=4294967295 -k perm_mod" "$audit_rules" &&
           grep -q "^-a always,exit -F arch=b64 -S creat -S open -S openat -S truncate -S ftruncate -F exit=-EACCES -F auid>=1000 -F auid!=4294967295 -k access" "$audit_rules" &&
           grep -q "^-a always,exit -F arch=b32 -S creat -S open -S openat -S truncate -S ftruncate -F exit=-EACCES -F auid>=1000 -F auid!=4294967295 -k access" "$audit_rules" &&
           grep -q "^-a always,exit -F arch=b64 -S creat -S open -S openat -S truncate -S ftruncate -F exit=-EPERM -F auid>=1000 -F auid!=4294967295 -k access" "$audit_rules" &&
       grep -q "^-a always,exit -F arch=b32 -S creat -S open -S openat -S truncate -S ftruncate -F exit=-EPERM -F auid>=1000 -F auid!=4294967295 -k access" "$audit_rules"; then
        echo "#Check 13. $audit_rules == Pass" >> "$OUTPUT_FILE"
    else
        echo "#Check 13. $audit_rules == Fail" >> "$OUTPUT_FILE"
    fi
else
    echo "#Check 13. File konfigurasi system-auth tidak ditemukan di $audit_rules == Fail" >> "$OUTPUT_FILE"
fi

#Check 14.
if command -v iptables &> /dev/null; then
    echo "#Check 14. Iptables == Pass" >> "$OUTPUT_FILE"
else
    echo "#Check 14.Iptables == Fail" >> "$OUTPUT_FILE"
fi

#Check 15.
sysctl_config="/etc/sysctl.conf"

# Mengecek apakah file konfigurasi sysctl.conf ada
if [ -f "$sysctl_config" ]; then
    # Mengecek status net.ipv6.conf.all.disable_ipv6
    if grep -q "^net.ipv6.conf.all.disable_ipv6\s*=\s*1" "$sysctl_config" &&
       grep -q "^net.ipv6.conf.default.disable_ipv6\s*=\s*1" "$sysctl_config"; then
        echo "#Check 15. Status ipv6 Non Aktif == Pass" >> "$OUTPUT_FILE"
    else
        echo "#Check 15. Status ipv6 Aktif == Fail" >> "$OUTPUT_FILE"
    fi
else
    echo "#Check 15. File konfigurasi $sysctl_config tidak ditemukan == Fail" >> "$OUTPUT_FILE"
fi

file_path="/etc/inetd"

if [ -e "$file_path" ]; then
    if [ -s "$file_path" ]; then
        services=("datetime" "discard" "time" "shell" "exec" "talk" "ntalk" "telnet" "tftp")

        for service in "${services[@]}"; do
            if grep -qE "^[[:space:]]*${service}[[:space:]]+" "$file_path"; then
                echo "#Check 16. Service $service diaktifkan dalam $file_path == Pass" >> "$OUTPUT_FILE"
            else
                echo "#Check 16. Service $service tidak diaktifkan dalam $file_path == Pass" >> "$OUTPUT_FILE"
            fi
        done
    else
        echo "#Check 16. File $file_path kosong == Pass" >> "$OUTPUT_FILE"
    fi
else
    echo "#Check 16. File $file_path tidak ditemukan == Pass" >> "$OUTPUT_FILE"
fi

echo "Selesai melakukan check hardening silahkan lihat hasilnya pada $OUTPUT_FILE"