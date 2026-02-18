#!/usr/bin/env bash
#═══════════════════════════════════════════════════════════════════════════════
#  SENSITIVE DATA SEARCH - Advanced Secret & Sensitive File Detector
#  Usage: bash sensitive-search.sh -f <urls.txt> [options]
#═══════════════════════════════════════════════════════════════════════════════

# -------------------- Colors --------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
GRAY='\033[0;90m'
NC='\033[0m'
BOLD='\033[1m'

# -------------------- Defaults --------------------
INPUT_FILE=""
OUTPUT_DIR=""
SILENT=false
ONLY_CATEGORY=""

usage() {
  cat << EOF

${BOLD}SENSITIVE DATA SEARCH${NC}
Usage: $0 -f <urls.txt> [options]

Options:
  -f, --file <file>       Input file with URLs (required)
  -o, --output <dir>      Output directory (default: sensitive_<timestamp>)
  -c, --category <name>   Run only one category (files|secrets|tokens|cloud|db|infra)
  -s, --silent            Silent mode (no banner)
  -h, --help              Show help

EOF
}

# -------------------- Args --------------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    -f|--file)     INPUT_FILE="$2"; shift 2 ;;
    -o|--output)   OUTPUT_DIR="$2"; shift 2 ;;
    -c|--category) ONLY_CATEGORY="$2"; shift 2 ;;
    -s|--silent)   SILENT=true; shift ;;
    -h|--help)     usage; exit 0 ;;
    *) echo "Unknown option: $1"; usage; exit 1 ;;
  esac
done

if [ -z "$INPUT_FILE" ]; then
  usage
  printf "%b\n" "${RED}[✗]${NC} Input file is required. Use -f <urls.txt>"
  exit 1
fi

if [ ! -f "$INPUT_FILE" ]; then
  printf "%b\n" "${RED}[✗]${NC} File not found: $INPUT_FILE"
  exit 1
fi

TOTAL_LINES="$(wc -l < "$INPUT_FILE" 2>/dev/null || echo 0)"
if [ "$TOTAL_LINES" -eq 0 ]; then
  printf "%b\n" "${RED}[✗]${NC} Input file is empty."
  exit 1
fi

# -------------------- Banner --------------------
print_banner() {
  [ "$SILENT" = true ] && return 0
  printf "%b\n" "${MAGENTA}"
  cat << "BANNER"
╔══════════════════════════════════════════════════════════╗
║                                                          ║
║   ███████╗███████╗███╗   ██╗███████╗██╗████████╗██╗   ║
║   ██╔════╝██╔════╝████╗  ██║██╔════╝██║╚══██╔══╝██║   ║
║   ███████╗█████╗  ██╔██╗ ██║███████╗██║   ██║   ██║   ║
║   ╚════██║██╔══╝  ██║╚██╗██║╚════██║██║   ██║   ██║   ║
║   ███████║███████╗██║ ╚████║███████║██║   ██║   ██║   ║
║   ╚══════╝╚══════╝╚═╝  ╚═══╝╚══════╝╚═╝   ╚═╝   ╚═╝   ║
║                                                          ║
║         🔍 Sensitive Data & Secret Finder 🔍             ║
╚══════════════════════════════════════════════════════════╝
BANNER
  printf "%b\n" "${NC}"
}

# -------------------- Spinner --------------------
SPINNER_PID=""
spinner_start() {
  local msg="$1"
  local frames=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
  local i=0
  printf "%b" "[${frames[0]}] ${msg}..."
  ( while true; do
      i=$(( (i + 1) % ${#frames[@]} ))
      printf "\r%b" "[${frames[$i]}] ${msg}..."
      sleep 0.12
    done ) &
  SPINNER_PID=$!
}
spinner_stop() {
  if [ -n "${SPINNER_PID}" ] && kill -0 "${SPINNER_PID}" 2>/dev/null; then
    kill "${SPINNER_PID}" 2>/dev/null || true
    wait "${SPINNER_PID}" 2>/dev/null || true
  fi
  SPINNER_PID=""
  printf "\r%b\n" "[${GREEN}✓${NC}] $1"
}

success() { printf "%b\n" "${GREEN}[✓]${NC} $*"; }
warning() { printf "%b\n" "${YELLOW}[!]${NC} $*"; }
error()   { printf "%b\n" "${RED}[✗]${NC} $*" >&2; }
section() {
  echo ""
  printf "%b\n" "${CYAN}[${1}]${NC}"
}

# -------------------- Setup output --------------------
TS="$(date +%Y%m%d_%H%M%S)"
[ -z "$OUTPUT_DIR" ] && OUTPUT_DIR="sensitive_${TS}"
mkdir -p "$OUTPUT_DIR"

SUMMARY_FILE="$OUTPUT_DIR/SUMMARY.txt"
ALL_HITS="$OUTPUT_DIR/all_hits.txt"
: > "$ALL_HITS"

print_banner

printf "%b\n" "${GRAY}  Input:   $INPUT_FILE ($TOTAL_LINES URLs)${NC}"
printf "%b\n" "${GRAY}  Output:  $OUTPUT_DIR${NC}"
echo ""

# ================== CATEGORY FUNCTIONS ==================

run_category() {
  local name="$1"
  local label="$2"
  local color="$3"
  local pattern="$4"
  local outfile="$OUTPUT_DIR/${name}.txt"

  [ -n "$ONLY_CATEGORY" ] && [ "$ONLY_CATEGORY" != "$name" ] && return 0

  spinner_start "$label"
  grep -aiE "$pattern" "$INPUT_FILE" 2>/dev/null | sort -u > "$outfile" || true
  local count
  count="$(wc -l < "$outfile" 2>/dev/null || echo 0)"
  spinner_stop "$label → ${count} found"

  if [ "$count" -gt 0 ]; then
    cat "$outfile" >> "$ALL_HITS"
    while IFS= read -r line; do
      printf "%b\n" "    ${color}${line}${NC}"
    done < "$outfile"
    echo ""
  fi
}

# ================== CATEGORIES ==================

section "CATEGORY 1 - SENSITIVE FILES & EXTENSIONS"
run_category "sensitive_files" "Sensitive file extensions" "$RED" \
  '\.(zip|rar|tar\.gz|tar|gz|tgz|7z|bz2|xz|config|conf|cfg|ini|log|logs|bak|backup|old|orig|save|swp|tmp|temp|cache|sql|db|sqlite|sqlite3|dump|mdb|accdb|java|class|jar|war|ear|apk|ipa|exe|dll|sh|bash|py|rb|php|asp|aspx|jsp|xml|yaml|yml|toml|json|csv|xlsx|xls|doc|docx|pptx|pdf|txt|htaccess|htpasswd|env|npmrc|netrc|gitconfig|DS_Store|Thumbs\.db)(\?.*)?$'

section "CATEGORY 2 - API KEYS & SECRETS"
run_category "api_keys" "API keys & secrets" "$RED" \
  '(access_key|access_token|api_key|api_key_secret|api_key_sid|api_secret|apikey|apisecret|apiSecret|app_key|app_secret|appkey|appkeysecret|application_key|appsecret|auth_token|authorizationToken|authsecret|client_secret|client_zpk_secret_key|consumer_key|consumer_secret|encryption_key|encryption_password|private_key|secret_key|secret_token|signing_key|signing_secret)["\s]*[=:>|]{1,2}["\s]*[0-9A-Za-z\-_=+/]{8,}'

section "CATEGORY 3 - CLOUD CREDENTIALS"
run_category "cloud_creds" "Cloud credentials (AWS/GCP/Azure)" "$MAGENTA" \
  '(aws_access_key_id|aws_secret_access_key|aws_access|aws_key|aws_secret|aws_token|AWSSecretKey|amazon_secret|amazonaws|bucketeer_aws|dynamoaccesskeyid|dynamosecretaccesskey|s3_bucket|s3_key|s3_secret|azure_client_id|azure_client_secret|azure_tenant|azure_subscription|gcp_key|google_api_key|google_application_credentials|GOOGLE_CLOUD|AIza[0-9A-Za-z\-_]{35}|arn:aws:[a-z0-9\-]+:[a-z0-9\-]*:[0-9]{12})'

section "CATEGORY 4 - DATABASE CREDENTIALS"
run_category "db_creds" "Database credentials" "$YELLOW" \
  '(database_password|database_url|db_password|db_pass|db_server|db_username|db_user|db_host|db_name|dbpasswd|dbpassword|dbuser|mongo_uri|mongodb_uri|mysql_password|mysql_root_password|postgres_password|redis_password|connectionstring|conn\.login|jdbc:|mongodb\+srv://|mysql://|postgres://|postgresql://|redis://)["\s]*[=:>|]{1,2}["\s]*[^\s&"]{4,}'

section "CATEGORY 5 - TOKENS & AUTH"
run_category "tokens" "Tokens & auth headers" "$CYAN" \
  '(access_token|bearer[_\s]token|refresh_token|id_token|jwt|oauth_token|oauth_consumer_key|oauth_signature|session_token|csrf_token|xsrf_token|_token|laravel_session|phpsessid|jsessionid|wp-nonce|X-Auth-Token|Authorization)["\s]*[=:>|]{1,2}["\s]*[0-9A-Za-z\-_.=+/]{8,}'

section "CATEGORY 6 - CI/CD & DEVOPS SECRETS"
run_category "cicd_secrets" "CI/CD & DevOps secrets" "$BLUE" \
  '(travis_token|circle_token|circleci|github_token|github_pat|gh_token|gitlab_token|bitbucket_password|jenkins_password|jenkins_token|codecov_token|coveralls_token|npm_token|npm_auth_token|pypi_password|rubygems_auth_token|sonar_token|sonarqube_token|artifactory_password|nexus_password|docker_hub_password|docker_pass|docker_password|dockerhub_password|heroku_api_key|vercel_token|netlify_token|railway_token|render_api_key)["\s]*[=:>|]{1,2}["\s]*[^\s&"]{8,}'

section "CATEGORY 7 - INTERNAL INFRASTRUCTURE"
run_category "infra" "Internal infrastructure endpoints" "$YELLOW" \
  '/(admin|administrator|wp-admin|wp-login|phpmyadmin|adminer|cpanel|whm|plesk|webmin|directadmin|panel|dashboard|backend|backoffice|console|control|portal|manager|manage|setup|install|actuator|actuator/env|actuator/health|actuator/info|actuator/metrics|swagger|swagger-ui|api-docs|openapi|graphiql|graphql/playground|\_\_debug\_\_|debug|test|staging|dev|internal|intranet|localhost|127\.0\.0\.1|192\.168\.|10\.|172\.(1[6-9]|2[0-9]|3[01])\.)[/?\s]'

section "CATEGORY 8 - EXPOSED CONFIG & ENV FILES"
run_category "config_files" "Exposed config & env files" "$RED" \
  '(\.env|\.env\.|env\.php|env\.rb|environment\.rb|application\.yml|config\.yml|config\.json|config\.xml|settings\.py|settings\.php|configuration\.php|wp-config\.php|database\.yml|database\.php|secrets\.yml|credentials\.yml\.enc|master\.key|\.git/config|\.svn/entries|\.hg/hgrc|composer\.json|package\.json|Gemfile\.lock|requirements\.txt|Dockerfile|docker-compose\.yml|\.travis\.yml|\.circleci/config\.yml|appspec\.yml|buildspec\.yml|serverless\.yml|\.github/workflows)(\?.*)?$'

section "CATEGORY 9 - GOOGLE / THIRD-PARTY API KEYS"
run_category "thirdparty_keys" "Third-party API keys" "$MAGENTA" \
  '(algolia_admin_key|algolia_api_key|algolia_app_id|aos_key|apidocs|b2_app_key|bintray_apikey|bintray_key|bluemix_api_key|browserstack_access_key|cloudant_password|cloudflare_api_key|cloudflare_auth_key|cloudinary_api_secret|cloudinary_name|datadog_api_key|datadog_app_key|digitalocean_ssh_key|dropbox_token|facebook_secret|firebase_api_key|firebase_url|github_client_secret|google_maps_key|intercom_secret|mailchimp_api_key|mailgun_api_key|mandrill_apikey|mapbox_token|mixpanel_token|new_relic_license_key|pagerduty_api_key|rollbar_access_token|salesforce_password|segment_write_key|sendgrid_api_key|sentry_dsn|slack_api_token|slack_token|slack_webhook|square_access_token|stripe_secret_key|stripe_api_key|telegram_bot_token|twilio_account_sid|twilio_auth_token|twitter_consumer_key|twitter_secret|vault_token|zendesk_token)["\s]*[=:>|]{1,2}["\s]*[^\s&"]{8,}'

section "CATEGORY 10 - JWT TOKENS IN URLS"
run_category "jwt_in_urls" "JWT tokens in URLs" "$CYAN" \
  'eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}'

section "CATEGORY 11 - OPEN REDIRECT"
run_category "open_redirect" "Open redirect parameters" "$YELLOW" \
  '(\?|&)(url|redirect|next|return|returnurl|return_url|goto|dest|destination|target|redir|forward|continue|location|from|ref|referer|out|view|to|link|jump|navigate|callback|successurl|failureurl|cancelurl|returnto)=https?://'

section "CATEGORY 12 - DEBUG & STACK TRACES"
run_category "debug_info" "Debug & error endpoints" "$GRAY" \
  '/(debug|test|trace|stack|exception|error|phpinfo|server-status|server-info|status|health|ping|version|info|metrics|stats|profiler|telescope|horizon|clockwork|_profiler|__profiler|ray|ignition|whoops)(\?.*)?$'

# ================== DEDUP ALL HITS ==================
sort -u "$ALL_HITS" -o "$ALL_HITS" 2>/dev/null || true
TOTAL_HITS="$(wc -l < "$ALL_HITS" 2>/dev/null || echo 0)"

# ================== SUMMARY ==================
echo ""
printf "%b\n" "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
printf "%b\n" "                  ${BOLD}SCAN SUMMARY${NC}"
printf "%b\n" "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo ""

declare -A CAT_LABELS=(
  [sensitive_files]="Sensitive file extensions"
  [api_keys]="API keys & secrets"
  [cloud_creds]="Cloud credentials"
  [db_creds]="Database credentials"
  [tokens]="Tokens & auth"
  [cicd_secrets]="CI/CD & DevOps secrets"
  [infra]="Internal infrastructure"
  [config_files]="Config & env files"
  [thirdparty_keys]="Third-party API keys"
  [jwt_in_urls]="JWT tokens in URLs"
  [open_redirect]="Open redirect"
  [debug_info]="Debug endpoints"
)

# write summary file
{
  echo "SENSITIVE DATA SEARCH REPORT"
  echo "============================="
  echo "Input:   $INPUT_FILE ($TOTAL_LINES URLs)"
  echo "Date:    $(date)"
  echo ""
  echo "RESULTS BY CATEGORY:"
} > "$SUMMARY_FILE"

for cat in sensitive_files api_keys cloud_creds db_creds tokens cicd_secrets infra config_files thirdparty_keys jwt_in_urls open_redirect debug_info; do
  f="$OUTPUT_DIR/${cat}.txt"
  [ ! -f "$f" ] && continue
  n="$(wc -l < "$f" 2>/dev/null || echo 0)"
  label="${CAT_LABELS[$cat]}"
  if [ "$n" -gt 0 ]; then
    printf "  %b%-30s%b %b%-6s%b  → %b%s%b\n" "${GREEN}" "$label" "${NC}" "${RED}${BOLD}" "$n" "${NC}" "${GRAY}" "$f" "${NC}"
    echo "  $label: $n  →  $f" >> "$SUMMARY_FILE"
  else
    # remove empty file so output dir stays clean
    rm -f "$f"
  fi
done

echo ""
printf "%b\n" "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
printf "  %-30s %b%s%b\n" "TOTAL UNIQUE HITS:" "${RED}${BOLD}" "$TOTAL_HITS" "${NC}"
printf "%b\n" "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo ""
printf "  %-20s %s\n" "All hits:"   "$ALL_HITS"
printf "  %-20s %s\n" "Summary:"    "$SUMMARY_FILE"
printf "  %-20s %s\n" "Output dir:" "$OUTPUT_DIR/"
echo ""

{
  echo ""
  echo "TOTAL UNIQUE HITS: $TOTAL_HITS"
  echo ""
  echo "Output: $OUTPUT_DIR/"
} >> "$SUMMARY_FILE"
