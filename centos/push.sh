#!/bin/bash

#Push 1

OUTPUT_FILE="./hasil_push.txt"
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

MOTD_FILE="/etc/motd"
EXPECTED_TEXT="WARNING (PERINGATAN) !!! All access to this computer is forbidden without authorization from BCAF's authorized personnel.
Violation to this will be prosecuted.This service is restricted to authorized users only.
All activities on this system are logged.
Unautorized access will be fully investigated and reported to the appropriate law enforcement agancies"

if [ -e "$MOTD_FILE" ]; then
    if grep -q "$EXPECTED_TEXT" "$MOTD_FILE"; then
        echo "Push 1. File /etc/motd sudah ada dan berisi teks yang diharapkan == Pass" >> "$OUTPUT_FILE"
    else
        echo "$EXPECTED_TEXT" > "$MOTD_FILE"
        echo "Push 1. Teks telah ditambahkan ke dalam file /etc/motd == Pass" >> "$OUTPUT_FILE"
    fi
else
    echo "$EXPECTED_TEXT" > "$MOTD_FILE"
    echo "Push 1. File /etc/motd telah dibuat dan teks telah ditambahkan == Pass" >> "$OUTPUT_FILE"
fi


#push 2

MOTD_FILE="/etc/motd"
ISSUE_NET_FILE="/etc/issue.net"

if [ -e "$MOTD_FILE" ]; then
    if [ -e "$ISSUE_NET_FILE" ]; then
        cp "$MOTD_FILE" "$ISSUE_NET_FILE"
        echo "Push 2. File /etc/issue.net berhasil diperbarui == Pass" >> "$OUTPUT_FILE"
    else
        cp "$MOTD_FILE" "$ISSUE_NET_FILE"
        echo "Push 2. File /etc/issue.net berhasil dibuat == Pass" >> "$OUTPUT_FILE"
    fi
else
    echo "Push 2. File /etc/motd tidak ditemukan == Fail" >> "$OUTPUT_FILE"
fi

#push 3

SSHD_CONFIG_FILE="/etc/ssh/sshd_config"
NEW_CONFIG_SSHD="
LogLevel INFO
X11Forwarding no
MaxAuthTries 10
IgnoreRhosts yes
ClientAliveInterval 300
ClientAliveCountMax 0
PermitRootLogin no
"

if [ -e "$SSHD_CONFIG_FILE" ]; then
    cp "$SSHD_CONFIG_FILE" "$SSHD_CONFIG_FILE.bak"
    sed -i '/LogLevel INFO/d' "$SSHD_CONFIG_FILE"
    sed -i '/X11Forwarding no/d' "$SSHD_CONFIG_FILE"
    sed -i '/MaxAuthTries 10/d' "$SSHD_CONFIG_FILE"
    sed -i '/IgnoreRhosts yes/d' "$SSHD_CONFIG_FILE"
    sed -i '/ClientAliveInterval 300/d' "$SSHD_CONFIG_FILE"
    sed -i '/ClientAliveCountMax 0/d' "$SSHD_CONFIG_FILE"
    sed -i '/PermitRootLogin no/d' "$SSHD_CONFIG_FILE"
    echo "$NEW_CONFIG_SSHD" >> "$SSHD_CONFIG_FILE"

    echo "Push 3. Konfigurasi /etc/ssh/sshd_config == Pass" >> "$OUTPUT_FILE"
else
    echo "Push 3. File /etc/ssh/sshd_config tidak ditemukan. == Fail" >> "$OUTPUT_FILE"
fi

#push 4

PWQUALITY_CONF_FILE="/etc/security/pwquality.conf"
NEW_CONFIG_PWQUALITY="
minlen = 6
dcredit = 1
ucredit = 1
lcredit = 1
usercheck = 1
"

if [ -e "$PWQUALITY_CONF_FILE" ]; then
    cp "$PWQUALITY_CONF_FILE" "$PWQUALITY_CONF_FILE.bak"
    sed -i '/minlen/d' "$PWQUALITY_CONF_FILE"
    sed -i '/dcredit/d' "$PWQUALITY_CONF_FILE"
    sed -i '/ucredit/d' "$PWQUALITY_CONF_FILE"
    sed -i '/lcredit/d' "$PWQUALITY_CONF_FILE"

    echo "$NEW_CONFIG_PWQUALITY" >> "$PWQUALITY_CONF_FILE"

    echo "Push 4. Konfigurasi baru telah ditambahkan pada /etc/security/pwquality.conf == Pass" >> "$OUTPUT_FILE"
else
    echo "Push 4. File /etc/security/pwquality.conf tidak ditemukan == Fail" >> "$OUTPUT_FILE"
fi

#push 5

system_auth="/etc/pam.d/system-auth"
password_auth="/etc/pam.d/password-auth"

new_config_pass_sys="password    requisite     pam_pwquality.so try_first-pass local_users_only retry=10 remember=12 authtok_type="

if [ -e "$system_auth" ] || [ -e "$password_auth" ]; then
    if grep -q "$new_config_pass_sys" "$password_auth"; then
        echo "Push 5.1. Konfigurasi $password_auth == Pass" >> "$OUTPUT_FILE"
    else
        sed -i '/password\s*requisite\s*pam_pwquality\.so/d' "$password_auth"
        echo "$new_config_pass_sys" >> "$password_auth"
        echo "Push 5.1. Konfigurasi pada $password_auth == berhasil ditambahkan == Pass" >> "$OUTPUT_FILE"
    fi

    if grep -q "$new_config_pass_sys" "$system_auth"; then
        echo "Push 5.2. Konfigurasi $system_auth == Pass" >> "$OUTPUT_FILE"
    else
        sed -i '/password\s*requisite\s*pam_pwquality\.so/d' "$system_auth"
        echo "$new_config_pass_sys" >> "$system_auth"
        echo "Push 5.2. konfigurasi $system_auth berhasil ditambahkan == Pass" >> "$OUTPUT_FILE"
    fi
else
    echo "Push 5. File $system_auth & $password_auth tidak ditemukan == Fail" >> "$OUTPUT_FILE"
fi

#push 6 

login_defs_file="/etc/login.defs"

desired_pass_max_days="PASS_MAX_DAYS 35"
desired_pass_min_days="PASS_MIN_DAYS 1"
desired_pass_warn_age="PASS_WARN_AGE 14"

sed_command="s/^PASS_MAX_DAYS.*/$desired_pass_max_days/; s/^PASS_MIN_DAYS.*/$desired_pass_min_days/; s/^PASS_WARN_AGE.*/$desired_pass_warn_age/"

if [ -e "$login_defs_file" ]; then
    if grep -q "^PASS_MAX_DAYS\|^PASS_MIN_DAYS\|^PASS_WARN_AGE" "$login_defs_file"; then
        sed -i "$sed_command" "$login_defs_file"
        echo "Push 6. Konfigurasi pada $login_defs_file == Pass" >> "$OUTPUT_FILE"
    else
        echo "Push 6. Konfigurasi pada $login_defs_file sudah dilakukan == Pass" >> "$OUTPUT_FILE"
    fi
else
    echo "Push 6. File $login_defs_file tidak ditemukan == Fail"
fi

#push 7

result=$(grep "^root:" /etc/passwd | cut -f4 -d:)

if [ "$result" -eq 0 ]; then
    echo "Push 7. grep "^root:" /etc/passwd | cut -f4 -d: $result == Pass" >> "$OUTPUT_FILE"
else
    usermod -g 0 root
    echo "Push 7. konfigurasi grep "^root:" /etc/passwd | cut -f4 -d: berhasil ditambahkan == Pass" >> "$OUTPUT_FILE"
fi

#push8

su_pam_file="/etc/pam.d/su"
desired_config_pamsu="auth required pam_wheel.so use_uid"

if [ -e "$su_pam_file" ]; then
    if grep -q "^#.*$desired_config_pamsu" "$su_pam_file"; then
        sed -i "s/^#.*$desired_config_pamsu/$desired_config_pamsu/" "$su_pam_file"
        echo "Push 8. Konfigurasi /etc/pam.d/su berhasil dilakukan == Pass" >> "$OUTPUT_FILE"
    elif grep -q "$desired_config_pamsu" "$su_pam_file"; then
        echo "konfigurasi /etc/pam.d/su sudah dilakukan == Pass" >> "$OUTPUT_FILE"
    else
        echo "$desired_config_pamsu" >> "$su_pam_file"
        echo "Push 8. Konfigurasi berhasil ditambahkan == Pass" >> "$OUTPUT_FILE"
    fi
else
    echo "Push 8. File $su_pam_file tidak ditemukan == Fail" >> "$OUTPUT_FILE"
fi

sudo adduser bcafmaster --create-home --password C8s0f09
sudo usermod -aG wheel bcafmaster
sudo sh -c 'echo "%wheel  ALL=(ALL)       ALL" >> /etc/sudoers'

echo "User bcafmaster ditambahkan ke wheel group." >> "$OUTPUT_FILE"

# Push 9
chrony_conf_file="/etc/chrony.conf"

desired_server_config="server wsadc1809001.bcaf.co.id"

if [ -e "$chrony_conf_file" ]; then
    if grep -q "$desired_server_config" "$chrony_conf_file"; then
        echo "Push 9. Konfigurasi $chrony_conf_file sudah ada == Pass" >> "$OUTPUT_FILE"
    else
        echo "$desired_server_config" >> "$chrony_conf_file"
        echo "Push 9. Konfigurasi berhasil ditambahkan ke $chrony_conf_file == Pass" >> "$OUTPUT_FILE"
        systemctl restart chronyd
        systemctl enable chronyd
        echo "Push 9. chronyd restarted and enabled == Pass" >> "$OUTPUT_FILE"
    fi
else
    touch "$chrony_conf_file"
    
    echo "$desired_server_config" >> "$chrony_conf_file"
    echo "Push 9. File dan konfigurasi baru berhasil dibuat == Pass" >> "$OUTPUT_FILE"
    
    systemctl restart chronyd
    systemctl enable chronyd
    echo "Push 9. chronyd restarted and enabled == Pass" >> "$OUTPUT_FILE"
fi

#push10
auditd_conf_file="/etc/audit/auditd.conf"

desired_max_log_file="max_log_file = 50"
desired_max_log_file_action="max_log_file_action = ROTATE"

sed_command="s/^max_log_file.*/$desired_max_log_file/; s/^max_log_file_action.*/$desired_max_log_file_action/"

if [ -e "$audit_rules_file" ]; then
    if grep -q -e "^max_log_file" -e "^max_log_file_action" "$auditd_conf_file"; then
        sed -i "$sed_command" "$auditd_conf_file"
        echo "Push 10. Konfigurasi berhasil dilakukan pada $auditd_conf_file == Pass" >> "$OUTPUT_FILE"
        service auditd reload
        echo "auditd service restarted."
    else
        echo " Push 10. Konfigurasi sudah dilakukan pada file $auditd_conf_file== Pass" >> "$OUTPUT_FILE"
    fi
else
    echo "Push 10. File $auditd_conf_file tidak ditemukan" >> "$OUTPUT_FILE"
fi


#Push11
audit_rules_file="/etc/audit/rules.d/audit.rules"

new_rules="
## First rule - delete all
-D

## Incrase the buffers to survive stress event
## Make this bigger for bussy systems
-b 8192

##Set flailure mode to syslog
-f 1

-w /etc/group -p wa -k identity
-w /etc/passwd -p wa -k identity
-w /etc/shadow -p wa -k identity
-w /etc/gshadow -p wa -k identity
-w /etc/sudoers -p wa -k identity
-w /etc/security/opasswd -p wa -k identity
-a always,exit -F arch=b64 -S adjtimex -S settimeofday -k time-change
-a always,exit -F arch=b32 -S adjtimex -S settimeofday -S stime -k time-change
-a always,exit -F arch=b64 -S clock_settime -k time-change
-a always,exit -F arch=b32 -S clock_settime -k time-change
-w /etc/localtime -p wa -k time-change
-w /var/log/faillog -p wa -k logins
-w /var/log/lastlog -p wa -k logins
-w /var/log/tallylog -p wa -k logins
-a always,exit -F arch=b64 -S chmod -S fchmod -S fchmodat -F auid>=1000 -F auid!=4294967295 -k perm_mod
-a always,exit -F arch=b32 -S chmod -S fchmod -S fchmodat -F auid>=1000 -F auid!=4294967295 -k perm_mod
-a always,exit -F arch=b64 -S chown -S fchown -S fchownat -S lchown -F auid>=1000 -F auid!=4294967295 -k perm_mod
-a always,exit -F arch=b32 -S chown -S fchown -S fchownat -S lchown -F auid>=1000 -F auid!=4294967295 -k perm_mod
-a always,exit -F arch=b64 -S setxattr -S lsetxattr -S fsetxattr -S removexattr -S lremovexattr -S fremovexattr -F auid>=1000 -F auid!=4294967295 -k perm_mod
-a always,exit -F arch=b32 -S setxattr -S lsetxattr -S fsetxattr -S removexattr -S lremovexattr -S fremovexattr -F auid>=1000 -F auid!=4294967295 -k perm_mod
-a always,exit -F arch=b64 -S creat -S open -S openat -S truncate -S ftruncate -F exit=-EACCES -F auid>=1000 -F auid!=4294967295 -k access
-a always,exit -F arch=b32 -S creat -S open -S openat -S truncate -S ftruncate -F exit=-EACCES -F auid>=1000 -F auid!=4294967295 -k access
-a always,exit -F arch=b64 -S creat -S open -S openat -S truncate -S ftruncate -F exit=-EPERM -F auid>=1000 -F auid!=4294967295 -k access
-a always,exit -F arch=b32 -S creat -S open -S openat -S truncate -S ftruncate -F exit=-EPERM -F auid>=1000 -F auid!=4294967295 -k access
"

if [ -e "$audit_rules_file" ]; then
    echo "$new_rules" > "$audit_rules_file"
    echo "Push 11. Konfigurasi pada $audit_rules_file berhasil diperbaharui == Pass" >> "$OUTPUT_FILE"
else
    echo "Push 11. File tidak ditemukan: $audit_rules_file == Fail" >> "$OUTPUT_FILE"
fi


#push 12 
sysctl_conf="/etc/sysctl.conf"

desired_config1="net.ipv6.conf.all.disable_ipv6=1"
desired_config2="net.ipv6.conf.default.disable_ipv6=1"

if [ -e "$sysctl_conf" ]; then
    if grep -q "^$desired_config1" "$sysctl_conf" && grep -q "^$desired_config2" "$sysctl_conf"; then
        echo "Push 12. Konfigurasi IPv6 sudah ada dalam $sysctl_conf === Pass" >> "$OUTPUT_FILE"
    else
        echo "$desired_config1" >> "$sysctl_conf"
        echo "$desired_config2" >> "$sysctl_conf"
        echo "Push 12. Konfigurasi IPv6 berhasil ditambahkan ke $sysctl_conf == Pass" >> "$OUTPUT_FILE"
    fi
else
    echo "Push 12. File tidak ditemukan: $sysctl_conf" >> "$OUTPUT_FILE"
fi

#push 13

file_path="/etc/inetd"

if [ -e "$file_path" ]; then
    if [ -s "$file_path" ]; then
        services=("datetime" "discard" "time" "shell" "exec" "talk" "ntalk" "telnet" "tftp")

        for service in "${services[@]}"; do
            if grep -qE "^[[:space:]]*${service}[[:space:]]+" "$file_path"; then
                echo "Push 13. Service $service diaktifkan dalam $file_path == Pass" >> "$OUTPUT_FILE"
            else
                echo "Push 13. Service $service tidak diaktifkan dalam $file_path == Pass" >> "$OUTPUT_FILE"
            fi
        done
    else
        echo "Push 13. File $file_path kosong == Pass" >> "$OUTPUT_FILE"
    fi
else
    echo "Push 13. File $file_path tidak ditemukan == Pass" >> "$OUTPUT_FILE"
fi

echo "Selesai melakukan hardening silahkan lihat hasilnya pada $OUTPUT_FILE"