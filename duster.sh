#!/bin/bash

DEFAULT="/usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt"
THREADS=20

# Colors
YELLOW='\e[0;33m'
BLUE='\e[0;34m'
RED='\e[0;31m'
GREEN='\e[0;32m'
NC='\e[0m'


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
${RED}*                                                            *                              
${RED}**************************************************************

	"
	
}

# Usage and Options
function usage(){
	echo -e "${GREEN}USAGE:${NC}"
	echo -e " ./duster.sh -u <URL> -w <WORDLIST>"
	echo
	echo -e "${YELLOW}Options:${NS}"
	echo
	echo -e "-u 	URL of website (ex. https://example.com)\n"
	echo -e "-w 	Wordlist (optional, default is Dirbuster)\n"
	echo -e "-h 	Help\n"
	exit 0

}

# Create a unique directory inside the output directory to save the output results.
function create_dir(){
	dir_name=$(echo "$url" | sed 's~https\?://~~' | sed 's~/.*~~') # removing the 'https://' and '.com' from the URL to create the unique directory.
	mkdir -p "output/$dir_name"
	OUTPUT_DIR="$dir_name"
	
}

# Create a unique file to save the ouput.
function create_file(){
	timestamp=$(date +%Y%m%d_%H%M%S).txt # Using timestamp to create a unique file
	out_file="output/$OUTPUT_DIR/output_$timestamp"
	touch "$out_file"
	echo -e "${BLUE}[+] Output will be saved to: $out_file${NC}"
}

function mkurl(){
	base="${url%/}"
	echo "${base}/${1}"
}

function worker(){
	directory="$1"

	[[ -z "$directory" || "$directory" =~ ^# ]] && return 0
	full_url=$(mkurl "$directory")

	response=$(curl -o /dev/null --silent -Iw "{http_code}" "$full_url")

	case "$response" in
		200)
			echo -e "${GREEN}[200 FOUND]${NC} $full_url"
			echo "[200 Found] $full_url" >> $out_file
			;;
		403)
			echo -e "${YELLOW}[403 FORBIDDEN]${NC} $full_url"
			echo "[403 FORBIDDEN] $full_url" >> $out_file
			;;
	esac
 }

function bruteforce(){
	echo -e "${BLUE}[+] Starting brute force with $THREADS threads....${NC}"
	base="${url%/}"
	# Old Code 
	# while IFS= read -r directory; do
	#     # Skip empty lines & comments
	#     [[ -z "$directory" || "$directory" =~ ^# ]] && continue
	# 
	#     # Build URL
	#     list="${base}/${directory}"
	# 
	#     # Fetch response code
	#     response_code=$(curl -o /dev/null --silent -Iw "%{http_code}" "$list")
	# 
	#     echo "[+]URL: $list - HTTP Code: $response_code"
	#     echo "$list - HTTP Code: $response_code" > "$outfile"
	# done < "$wlist"
	while IFS= read -r directory; do
		worker "$directory" &

		while [ "$(jobs -rp 2>/dev/null | wc -l)" -ge "$THREADS" ]; do
	    	sleep 0.1
		done
	
	done < "$wlist"
	wait
	    
}


function ctrl_c(){
	echo -e "\n${RED}[!] Keyboard Interrupt detected. Saving output and exiting...${NC}"
	echo "[PROGRAM STOPPED BY USER]" >> "$out_file"
	exit 0
}
trap ctrl_c SIGINT


function main(){
	banner

	while getopts "u:w:h" opt;do
		case "$opt" in
			u) url="$OPTARG" ;;
			w) wlist="$OPTARG" ;;
			h) usage ;;
			*) usage ;;
		esac
	done

	if [[ -z "$url" ]]; then
		echo -e "${RED}[!] URL is required${NC}"
		usage
	fi

	if [[ -z "$wlist" ]]; then
		wlist="$DEFAULT"
		echo -e "${YELLOW}[!] Wordlist not provided. Using default.${NC}"
	fi
	create_dir	
	create_file
	bruteforce 
	
}
main "$@"


