# Duster

A lightweight directory enumeration tool written in pure Bash. Built for CTF players, penetration testers, and anyone who needs a simple, hackable directory brute-forcer that just works.

## Why Another Directory Scanner?

I got tired of installing heavy tools on every fresh box during CTFs. Sometimes you're on a minimalist VM, sometimes you're SSH'd into a restricted environment, and sometimes you just want something you can read, understand, and tweak in 5 minutes.

Duster runs anywhere Bash and curl exist. No Python. No Go binaries. Just a script you can audit in one sitting.

## What It Does

Throws a wordlist at a web server and tells you what sticks. It'll find your `/admin` panels, `/backup` directories, and those `.bak` files someone forgot about.

The tool handles threading properly, follows directory redirects intelligently (no more spam about trailing slashes), and gives you clean output without drowning you in noise.

## Setup

```bash
git clone https://github.com/ShieldedDev/Duster.git
cd duster
chmod +x duster.sh
```

Make sure you have `curl` installed. You probably already do.

```bash
# Debian/Ubuntu
sudo apt install curl

# Arch
sudo pacusr -S curl

# Fedora/RHEL
sudo dnf install curl
```

## Basic Usage

Point it at a target:

```bash
./duster.sh -u https://target.com
```

That's it. It'll use a default wordlist and start hunting.

Want more control?

```bash
# Custom wordlist
./duster.sh -u https://target.com -w /path/to/wordlist.txt

# Crank up the speed
./duster.sh -u https://target.com -t 50

# Check for common file extensions
./duster.sh -u https://target.com -x

# Only show successful hits (clean output)
./duster.sh -u https://target.com -s

# Custom extensions for specific targets
./duster.sh -u https://target.com -e php,asp,jsp,bak
```

## All Options

```
-u <URL>       Target URL (required)
-w <WORDLIST>  Path to wordlist file
-t <THREADS>   Number of concurrent threads (default: 20)
-T <TIMEOUT>   Request timeout in seconds (default: 10)
-e <EXTS>      Check specific extensions (comma-separated)
-x             Enable extension checking with defaults
-f             Follow redirects
-a <AGENT>     Custom User-Agent string
-s             Show only 200 responses (less noise)
-v             Verbose mode (show everything)
-h             Help menu
```

## What You'll See

```
[200 FOUND] http://target.com/admin/ [DIR] (2048 bytes)
[200 FOUND] http://target.com/config.php (156 bytes)
[403 FORBIDDEN] http://target.com/private/ [DIR]
[200 FOUND] http://target.com/backup.zip (8192 bytes)
```

The tool automatically figures out when a redirect is just a directory trailing slash thing and follows it for you. No more seeing fifty `301` redirects that all just add a `/` at the end.

Results get saved to `output/target-name/scan_timestamp.txt` with a summary at the end.

## Real World Examples

**Quick CTF scan:**
```bash
./duster.sh -u http://10.10.11.123 -x -s
```

**Bug bounty recon with custom wordlist:**
```bash
./duster.sh -u https://target.com -w ~/wordlists/raft-large.txt -t 30 -x
```

**Hunting for specific files:**
```bash
./duster.sh -u https://target.com -e php,bak,old,zip,sql
```

**Being stealthy:**
```bash
./duster.sh -u https://target.com -t 10 -a "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"
```

## When To Use This

**CTFs** - Fast, portable, easy to tweak during a competition

**Pentesting restricted boxes** - When you can't install tooling but have Bash and curl

**Learning** - The code is straightforward. Good for understanding how directory brute-forcing works under the hood

**Quick recon** - Sometimes you just need to check if `/admin` exists before moving on

## How It Works

Pretty simple worker model:

1. Read wordlist line by line
2. Spawn background workers that probe each path
3. Limit concurrent workers based on thread count
4. Parse HTTP response codes from curl
5. Filter out noise (like automatic directory trailing slash redirects)
6. Log interesting findings

The threading is handled with Bash background jobs and a simple counter. Not fancy, but it works well enough.

## Technical Details

The tool sends HEAD requests by default (faster, less invasive). It tracks response codes, sizes, and redirect locations. When it sees a 301 redirect that's just adding a trailing slash, it automatically follows it and shows you the actual result instead of cluttering your output.

Extension checking works by testing each directory path with and without your specified extensions. Useful for finding `config.php`, `backup.zip`, `database.sql`, etc.

All output goes to timestamped files organized by target, so you can run multiple scans without losing history.

## Limitations

This is a Bash script that shells out to curl repeatedly. It's not going to match the speed of compiled scanners like gobuster or ffuf on massive wordlists. But for most CTF and lab scenarios, it's fast enough and way more convenient.

No fancy features like recursive scanning, authentication, or custom headers beyond User-Agent. Keep it simple.

## Contributing

Found a bug? Have an idea? Open an issue or send a PR. The code is meant to be readable and hackable.

## License

MIT. Do whatever you want with it.

## Acknowledgments

Built with inspiration from DirBuster, gobuster, and all those late-night CTF sessions where I wished I had a simple scanner I could just modify on the fly.

---

Made for hackers, by hackers. Happy hunting.
