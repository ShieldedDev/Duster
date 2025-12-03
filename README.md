
# 🚀 Duster – A Fast Bash-Based Directory Brute-Forcer

Duster is a lightweight, fast, and fully-bash directory brute-forcing tool written for CTFs, pentesting labs, and bug bounty recon.
It uses curl, background job parallelization, and a simple worker model to uncover hidden directories on web servers.

This tool exists for people who want a simple, portable, dependency-minimal brute-forcer that runs almost anywhere Linux does — without installing Go, Python libraries, or massive scanners.

## Why I Built This Tool
During many CTFs and web-app pentests, I repeatedly found myself needing:
    
   - A quick way to enumerate folders without installing heavy tools
   - Something that works on fresh Linux boxes, remote jump hosts, and VMs
   - A script I can modify, extend, or integrate into recon pipelines
   - A tool that is easy to read, easy to hack on, and fast enough to matter

Duster fills that gap:
A transparent, open, easily customizable brute-forcer written in pure Bash.

## 💡 Key Features

✔️ Configurable thread count for speed tuning

✔️ Uses curl for HTTP probing` (portable & dependable)

✔️ Shows 200 / 401 / 403 / 

✔️ Auto-creates output folder for each target

✔️ Timestamped result files

✔️ Color-coded terminal output

✔️ Graceful Ctrl+C handling

✔️ No external dependencies except curl

Perfect for CTFs, bug bounty automation, quick recon, or scripting exercises in Bash.


## 📦 Installation

### Clone the repository:

    git clone https://github.com/ShieldedDev/Duster
    cd Duster
    chmod +x duster.sh


### Install curl (if not already installed):

    sudo apt install curl     # Debian/Ubuntu
    sudo pacman -S curl       # Arch
    sudo dnf install curl     # Fedora

## 🎯 Usage
    ./duster.sh -u <URL> -w <WORDLIST>

### Options
    Flag	Description
    -u	    Target URL (required)
    -w  	Wordlist path (optional — default DirBuster list)
    -h	    Help menu

### Example
    ./duster.sh -u https://example.com -w /usr/share/wordlists/dirb/common.txt

### Sample Output

    [+] Output will be saved to: ./example.com/output_20251203_221513.txt
    [200 OK]        https://example.com/admin
    [403 FORBIDDEN] https://example.com/private
    [301 REDIRECT]  https://example.com/blog

## 🛠️ How It Works

- Duster uses a simple but effective internal flow:
- Reads each line of the wordlist
- Spawns a worker() in the background
- Limits running workers by thread count
- Sends HTTP requests via curl
- Logs interesting status codes (200, 401, 403, redirects)
- Saves output into timestamped files under a target-named directory
- This makes the tool fast, portable, and easy to modify.

## 🔥 When to Use Duster
 ✔️ CTFs / Wargames
 - Fast enumeration of challenge servers.
✔️ Bug Bounty Recon
 - Helps uncover:

        /admin
        /backup
        /dev
        /uploads
        /api
        /old

✔️ Pentesting on Restricted Systems

- When you only have:

    - Bash
    - curl
    - Minimal permissions
    - Duster still works.

✔️ Bash Learning

 - Great example of:

    - Argument parsing (getopts)
    - Parallelism with jobs
    - Signal handling (trap)
    - Using curl programmatically
