**NetPass Bruteforce** is a tool for automating basic security checks on a local network. It detects active services (SSH, FTP, RDP) and automatically checks authentication using a password dictionary.
# How to install and use?🚀 
Clone the repository 
```
git clone https://github.com/whitegertsok/NetPassBruteforce.git
```

Change to the directory
```
cd NetPassBruteforce
```
Give execution rights
```
chmod +x NetPassBrutforce.sh
```
And go
```
./NetPassBrutforce.sh
```

**Main functions:**
- Automatic detection of hosts in the local network via ARP
- Checking the availability of ports 22 (SSH), 21 (FTP), and 3389 (RDP)
- Full brute force of all passwords from the rockyou.txt dictionary for each service
- Testing anonymous access to FTP
- Support for multiple standard users for each service
- Saving results to a file

**Features:**
- Brute force of passwords from the rockyou.txt dictionary
- Timeouts to prevent freezes
- Visual progress and results indicators
- Support for major remote access protocols
# Requirements📢
- sshpass, curl, netcat, xfreerdp
- The rockyou.txt dictionary in the standard location /usr/share/wordlists/rockyou.txt
```
Let's try! :)
```
