#!/bin/bash

DEFAULT="/usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt"
THREADS=20
TIMEOUT=10
USER_AGENT="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
FOLLOW_REDIRECTS=false
CHECK_EXTENSIONS=false
EXTENSIONS="php,html,txt,asp,aspx,jsp,bak,old,zip,tar.gz"

# Colors
YELLOW='\e[0;33m'
BLUE='\e[0;34m'
RED='\e[0;31m'
GREEN='\e[0;32m'
CYAN='\e[0;36m'
MAGENTA='\e[0;35m'
NC='\e[0m'

# Counters
declare -i found_count=0
declare -i forbidden_count=0
declare -i redirect_count=0
declare -i total_checked=0

# Banner of the script
function banner(){
	echo -e "
${RED}**************************************************************                     
${RED}*                                                            *        
${RED}*                                                            *
${RED}*    ${GREEN} ██████╗ ██╗   ██╗███████╗████████╗███████╗██████╗      ${RED}*
${RED}*     ██╔══██╗██║   ██║██╔════╝╚══██╔══╝██╔════╝██╔══██╗     *
${RED}*     ██║  ██║██║   ██║███████╗   ██║   █████╗  ██████╔╝     *
${RED}*     ██║  ██║██║   ██║╚════██║   ██║   ██╔══╝  ██╔══██╗     *
${RED}*     ██████╔╝╚██████╔╝███████║   ██║   ███████╗██║  ██║     *
${RED}*     ╚═════╝  ╚═════╝ ╚══════╝   ╚═╝   ╚══════╝╚═╝  ╚═╝     *
${RED}*                                                            *
${RED}*                      v2.0 Enhanced                         *                              
${RED}**************************************************************

	"
}

# Usage and Options
function usage(){
	echo -e "${GREEN}USAGE:${NC}"
	echo -e " ./duster.sh -u <URL> [OPTIONS]"
	echo
	echo -e "${YELLOW}Required:${NC}"
	echo -e "  -u <URL>       Target URL (ex. https://example.com)\n"
	echo -e "${YELLOW}Optional:${NC}"
	echo -e "  -w <WORDLIST>  Path to wordlist (default: dirbuster medium)"
	echo -e "  -t <THREADS>   Number of threads (default: 20)"
	echo -e "  -T <TIMEOUT>   Request timeout in seconds (default: 10)"
	echo -e "  -e <EXTS>      Check file extensions (comma-separated, ex: php,html,txt)"
	echo -e "  -x             Enable extension checking with default extensions"
	echo -e "  -f             Follow redirects (default: false)"
	echo -e "  -a <AGENT>     Custom User-Agent string"
	echo -e "  -s             Show only found directories (hide 403s and redirects)"
	echo -e "  -v             Verbose mode (show all response codes)"
	echo -e "  -h             Show this help message\n"
	echo -e "${CYAN}Examples:${NC}"
	echo -e "  ./duster.sh -u https://example.com"
	echo -e "  ./duster.sh -u https://example.com -w custom.txt -t 50"
	echo -e "  ./duster.sh -u https://example.com -x -f"
	echo -e "  ./duster.sh -u https://example.com -e php,asp,aspx -s\n"
	exit 0
}

# Create output directory structure
function create_dir(){
	dir_name=$(echo "$url" | sed 's~https\?://~~' | sed 's~/.*~~' | sed 's/:.*//') 
	mkdir -p "output/$dir_name"
	OUTPUT_DIR="$dir_name"
}

# Create output file
function create_file(){
	timestamp=$(date +%Y%m%d_%H%M%S)
	out_file="output/$OUTPUT_DIR/scan_$timestamp.txt"
	touch "$out_file"
	
	# Write header to file
	{
		echo "======================================"
		echo "Directory Bruteforce Scan Results"
		echo "======================================"
		echo "Target: $url"
		echo "Wordlist: $wlist"
		echo "Threads: $THREADS"
		echo "Timeout: $TIMEOUT seconds"
		echo "User-Agent: $USER_AGENT"
		echo "Follow Redirects: $FOLLOW_REDIRECTS"
		echo "Check Extensions: $CHECK_EXTENSIONS"
		[[ "$CHECK_EXTENSIONS" == "true" ]] && echo "Extensions: $EXTENSIONS"
		echo "Scan Started: $(date)"
		echo "======================================"
		echo ""
	} > "$out_file"
	
	echo -e "${BLUE}[+] Output will be saved to: $out_file${NC}"
}

# Build URL properly
function mkurl(){
	local base="${url%/}"
	local path="$1"
	# Remove leading slash if present
	path="${path#/}"
	echo "${base}/${path}"
}

# Check if response indicates a valid/interesting finding
function is_interesting_response(){
	local code="$1"
	local size="$2"
	
	# Filter out common false positives by size
	# Adjust these values based on your target
	case "$code" in
		200)
			# Some sites return 200 for everything with same size
			# You might want to add size-based filtering here
			return 0
			;;
		403|301|302|307|308)
			return 0
			;;
		*)
			return 1
			;;
	esac
}

# Worker function - performs the actual directory check
function worker(){
	local directory="$1"
	local local_out_file="$2"
	
	[[ -z "$directory" || "$directory" =~ ^# ]] && return 0
	
	local full_url=$(mkurl "$directory")
	local curl_opts=(-o /dev/null --silent -Iw "%{http_code}|%{size_download}|%{redirect_url}" --max-time "$TIMEOUT" -A "$USER_AGENT")
	
	# Add follow redirects if enabled
	[[ "$FOLLOW_REDIRECTS" == "true" ]] && curl_opts+=(-L)
	
	# Perform request
	local response=$(curl "${curl_opts[@]}" "$full_url" 2>/dev/null)
	
	# Parse response
	IFS='|' read -r code size redirect_url <<< "$response"
	
	# Increment total counter
	((total_checked++))
	
	# Check if it's a trailing slash redirect (directory)
	local is_trailing_slash_redirect=false
	if [[ "$code" =~ ^30[127]$ ]] && [[ "$redirect_url" == "${full_url}/" ]]; then
		is_trailing_slash_redirect=true
		# This is a directory! Check it with trailing slash
		local dir_response=$(curl -o /dev/null --silent -Iw "%{http_code}|%{size_download}" --max-time "$TIMEOUT" -A "$USER_AGENT" "${full_url}/" 2>/dev/null)
		IFS='|' read -r code size <<< "$dir_response"
	fi
	
	# Skip if not interesting
	[[ "$VERBOSE" != "true" ]] && ! is_interesting_response "$code" "$size" && return 0
	
	# Display and log based on response code
	case "$code" in
		200)
			((found_count++))
			if [[ "$is_trailing_slash_redirect" == "true" ]]; then
				echo -e "${GREEN}[200 FOUND]${NC} ${full_url}/ ${CYAN}[DIR]${NC} (${size} bytes)"
				echo "[200 FOUND] ${full_url}/ [DIRECTORY] ($size bytes)" >> "$local_out_file"
			elif [[ -n "$redirect_url" ]] && [[ "$redirect_url" != "${full_url}/" ]]; then
				echo -e "${GREEN}[200 FOUND]${NC} $full_url ${CYAN}-> $redirect_url${NC} (${size} bytes)"
				echo "[200 FOUND] $full_url -> $redirect_url ($size bytes)" >> "$local_out_file"
			else
				echo -e "${GREEN}[200 FOUND]${NC} $full_url (${size} bytes)"
				echo "[200 FOUND] $full_url ($size bytes)" >> "$local_out_file"
			fi
			;;
		201)
			((found_count++))
			echo -e "${GREEN}[201 CREATED]${NC} $full_url (${size} bytes)"
			echo "[201 CREATED] $full_url ($size bytes)" >> "$local_out_file"
			;;
		204)
			((found_count++))
			echo -e "${GREEN}[204 NO CONTENT]${NC} $full_url"
			echo "[204 NO CONTENT] $full_url" >> "$local_out_file"
			;;
		301|302|307|308)
			# Skip trailing slash redirects in output unless verbose
			if [[ "$is_trailing_slash_redirect" != "true" ]]; then
				[[ "$SHOW_ONLY_FOUND" != "true" ]] && {
					((redirect_count++))
					if [[ -n "$redirect_url" ]]; then
						echo -e "${BLUE}[${code} REDIRECT]${NC} $full_url ${CYAN}-> $redirect_url${NC}"
						echo "[${code} REDIRECT] $full_url -> $redirect_url" >> "$local_out_file"
					else
						echo -e "${BLUE}[${code} REDIRECT]${NC} $full_url"
						echo "[${code} REDIRECT] $full_url" >> "$local_out_file"
					fi
				}
			fi
			;;
		401)
			[[ "$SHOW_ONLY_FOUND" != "true" ]] && {
				echo -e "${MAGENTA}[401 UNAUTHORIZED]${NC} $full_url"
				echo "[401 UNAUTHORIZED] $full_url" >> "$local_out_file"
			}
			;;
		403)
			[[ "$SHOW_ONLY_FOUND" != "true" ]] && {
				((forbidden_count++))
				if [[ "$is_trailing_slash_redirect" == "true" ]]; then
					echo -e "${YELLOW}[403 FORBIDDEN]${NC} ${full_url}/ ${CYAN}[DIR]${NC}"
					echo "[403 FORBIDDEN] ${full_url}/ [DIRECTORY]" >> "$local_out_file"
				else
					echo -e "${YELLOW}[403 FORBIDDEN]${NC} $full_url"
					echo "[403 FORBIDDEN] $full_url" >> "$local_out_file"
				fi
			}
			;;
		405)
			[[ "$VERBOSE" == "true" ]] && {
				echo -e "${CYAN}[405 METHOD NOT ALLOWED]${NC} $full_url"
				echo "[405 METHOD NOT ALLOWED] $full_url" >> "$local_out_file"
			}
			;;
		500|502|503)
			[[ "$VERBOSE" == "true" ]] && {
				echo -e "${RED}[${code} SERVER ERROR]${NC} $full_url"
				echo "[${code} SERVER ERROR] $full_url" >> "$local_out_file"
			}
			;;
		*)
			[[ "$VERBOSE" == "true" ]] && {
				echo -e "${CYAN}[${code}]${NC} $full_url (${size} bytes)"
				echo "[${code}] $full_url ($size bytes)" >> "$local_out_file"
			}
			;;
	esac
}

# Check extensions for a path
function check_with_extensions(){
	local base_path="$1"
	local local_out_file="$2"
	
	# First check the base path
	worker "$base_path" "$local_out_file" &
	while [ "$(jobs -rp 2>/dev/null | wc -l)" -ge "$THREADS" ]; do
		sleep 0.05
	done
	
	# Then check with each extension
	IFS=',' read -ra EXT_ARRAY <<< "$EXTENSIONS"
	for ext in "${EXT_ARRAY[@]}"; do
		worker "${base_path}.${ext}" "$local_out_file" &
		while [ "$(jobs -rp 2>/dev/null | wc -l)" -ge "$THREADS" ]; do
			sleep 0.05
		done
	done
}

# Main bruteforce function
function bruteforce(){
	echo -e "${BLUE}[+] Starting directory bruteforce...${NC}"
	echo -e "${BLUE}[+] Target: $url${NC}"
	echo -e "${BLUE}[+] Wordlist: $wlist${NC}"
	echo -e "${BLUE}[+] Threads: $THREADS${NC}"
	echo -e "${BLUE}[+] Timeout: $TIMEOUT seconds${NC}"
	[[ "$CHECK_EXTENSIONS" == "true" ]] && echo -e "${BLUE}[+] Extensions: $EXTENSIONS${NC}"
	echo ""
	
	local line_count=$(wc -l < "$wlist")
	echo -e "${CYAN}[*] Total entries to check: $line_count${NC}"
	echo ""
	
	while IFS= read -r directory; do
		# Skip empty lines & comments
		[[ -z "$directory" || "$directory" =~ ^# ]] && continue
		
		if [[ "$CHECK_EXTENSIONS" == "true" ]]; then
			check_with_extensions "$directory" "$out_file"
		else
			worker "$directory" "$out_file" &
			
			# Limit concurrent threads
			while [ "$(jobs -rp 2>/dev/null | wc -l)" -ge "$THREADS" ]; do
				sleep 0.05
			done
		fi
	done < "$wlist"
	
	# Wait for all background jobs to complete
	echo -e "\n${CYAN}[*] Waiting for remaining requests to complete...${NC}"
	wait
	
	# Print summary
	echo ""
	echo -e "${GREEN}=====================================${NC}"
	echo -e "${GREEN}        Scan Complete!${NC}"
	echo -e "${GREEN}=====================================${NC}"
	echo -e "${GREEN}[+] Found (200): $found_count${NC}"
	echo -e "${YELLOW}[+] Forbidden (403): $forbidden_count${NC}"
	echo -e "${BLUE}[+] Redirects: $redirect_count${NC}"
	echo -e "${CYAN}[+] Total checked: $total_checked${NC}"
	echo -e "${GREEN}[+] Results saved to: $out_file${NC}"
	echo ""
	
	# Write summary to file
	{
		echo ""
		echo "======================================"
		echo "Scan Summary"
		echo "======================================"
		echo "Scan Completed: $(date)"
		echo "Found (200): $found_count"
		echo "Forbidden (403): $forbidden_count"
		echo "Redirects: $redirect_count"
		echo "Total Checked: $total_checked"
		echo "======================================"
	} >> "$out_file"
}

# Interrupt handler
function ctrl_c(){
	echo -e "\n${RED}[!] Keyboard Interrupt detected. Cleaning up...${NC}"
	echo "[SCAN INTERRUPTED BY USER at $(date)]" >> "$out_file"
	
	# Kill all background jobs
	jobs -p | xargs -r kill 2>/dev/null
	wait 2>/dev/null
	
	# Print partial summary
	echo -e "\n${YELLOW}Partial Results:${NC}"
	echo -e "Found: $found_count | Forbidden: $forbidden_count | Checked: $total_checked"
	exit 1
}
trap ctrl_c SIGINT

# Initial connection test
function test_connection(){
	echo -e "${CYAN}[*] Testing connection to target...${NC}"
	
	local test_response=$(curl -o /dev/null --silent -Iw "%{http_code}" --max-time 5 -A "$USER_AGENT" "$url" 2>/dev/null)
	
	if [[ -z "$test_response" ]]; then
		echo -e "${RED}[!] Failed to connect to target. Please check the URL and try again.${NC}"
		exit 1
	fi
	
	echo -e "${GREEN}[+] Connection successful (HTTP $test_response)${NC}"
	echo ""
}

# Main function
function main(){
	banner
	
	while getopts "u:w:t:T:e:xa:fsvh" opt; do
		case "$opt" in
			u) url="$OPTARG" ;;
			w) wlist="$OPTARG" ;;
			t) THREADS="$OPTARG" ;;
			T) TIMEOUT="$OPTARG" ;;
			e) CHECK_EXTENSIONS=true; EXTENSIONS="$OPTARG" ;;
			x) CHECK_EXTENSIONS=true ;;
			a) USER_AGENT="$OPTARG" ;;
			f) FOLLOW_REDIRECTS=true ;;
			s) SHOW_ONLY_FOUND=true ;;
			v) VERBOSE=true ;;
			h) usage ;;
			*) usage ;;
		esac
	done
	
	# Validate required parameters
	if [[ -z "$url" ]]; then
		echo -e "${RED}[!] Error: URL is required${NC}\n"
		usage
	fi
	
	# Set default wordlist if not provided
	if [[ -z "$wlist" ]]; then
		wlist="$DEFAULT"
		echo -e "${YELLOW}[!] Wordlist not provided. Using default: $wlist${NC}"
	fi
	
	# Check if wordlist exists
	if [[ ! -f "$wlist" ]]; then
		echo -e "${RED}[!] Error: Wordlist file not found: $wlist${NC}"
		exit 1
	fi
	
	# Validate thread count
	if ! [[ "$THREADS" =~ ^[0-9]+$ ]] || [ "$THREADS" -lt 1 ]; then
		echo -e "${RED}[!] Error: Invalid thread count. Must be a positive integer.${NC}"
		exit 1
	fi
	
	# Test connection first
	test_connection
	
	# Create output directory and file
	create_dir
	create_file
	
	# Start the bruteforce
	bruteforce
}

main "$@"
