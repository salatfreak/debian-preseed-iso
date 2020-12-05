#!/bin/bash
set -euo pipefail

# Main function
main() {
  # Get parameters
  (( $# >= 1 )) || abort 'Preseed file parameter missing'
  (( $# == 1 )) || abort "Unexpected parameter \"$1\""
  local file="$1"

  # Print help if requested
  if [[ "$file" =~ ^-h|--help$ ]]; then usage; exit; fi

  # Read password
  local pw pc
  read -esp 'Enter password: '     pw || abort 'Reading password failed'
  echo >&2
  read -esp 'Re-enter password: '  pc || abort 'Reading password confirm failed'
  echo >&2
  [[ -n "$pw"       ]] || abort 'Password empty'
  [[ "$pw" == "$pc" ]] || abort 'Passwords dont match'

  # Create password hash
  local pw_hash; pw_hash="$(
    PW="$pw" python3 -c \
    "import crypt, os; print(crypt.crypt(os.environ['PW'], crypt.METHOD_SHA256))"
  )" || abort 'Hashing password failed'

  # Replace or insert password hash
  local pw_line="d-i passwd/user-password-crypted password $pw_hash"
  if grep -q '^d-i\spasswd\/user-password' "$file"; then
    sed "$file" \
      -e '0,/^d-i\spasswd\/user-password/{//i'"$pw_line" -e '}' \
      -e '/^d-i\spasswd\/user-password/d' ||
      abort 'Inserting password into file failed'
  else
    cat "$file" || abort 'Reading file failed'
    echo
    echo '# User password'
    echo "$pw_line" >> "$file" || abort 'Inserting password into file failed'
  fi
}

# Print usage info
usage() {
  cat <<END
Usage: insert-crypted-password.sh [PRESEED-FILE]

Reads a password and confirmation from stdin and prints the specified
PRESEED-FILE with the password hash inserted to STDOUT.
END
}

# Abort with error
abort() { local msg="$1"
  echo "[ERROR] $msg" >&2
  exit 1
}

# Call main function
main "$@"
