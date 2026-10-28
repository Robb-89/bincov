#!/usr/bin/env bash
#
# binconv - convert numbers between decimal, binary and hex,
#           and show text as ASCII bytes.
#
# Handles 0 to 4,294,967,295 (32 bits). The output grows to fit:
# 8 bits for 0-255, 16 bits up to 65,535, 32 bits after that.
#
# Usage:
#   ./binconv.sh 42            decimal input
#   ./binconv.sh 0b101010      binary input (starts with 0b)
#   ./binconv.sh 0x2A          hex input (starts with 0x)
#   ./binconv.sh --text yeah   show each letter as a byte
#   ./binconv.sh --help
#
# Works on macOS's built-in Bash 3.2 and on Linux.

MAX=4294967295   # biggest 32-bit number
MAX_BITS=32

# ---------------------------------------------------------------
# How many bits to show: the smallest of 8, 16 or 32 that fits.
# ---------------------------------------------------------------
bit_width() {
  local n=$1
  if   (( n <= 255 ));   then echo 8
  elif (( n <= 65535 )); then echo 16
  else                        echo 32
  fi
}

# ---------------------------------------------------------------
# Decimal -> binary, done by hand: biggest place first.
# If the place fits, write 1 and take it away; if not, write 0.
# The biggest place is worked out from the width instead of being
# typed in: for 8 bits it is 128, for 16 bits 32768, and so on.
# Each next place is half the one before.
# ---------------------------------------------------------------
to_binary() {
  local left=$1
  local width=$2
  local place=$(( 1 << (width - 1) ))   # value of the leftmost place
  local result=""

  while (( place >= 1 )); do
    if (( left >= place )); then
      result="${result}1"          # it fits: write a 1
      left=$(( left - place ))     # and take it away
    else
      result="${result}0"          # too big: write a 0
    fi
    place=$(( place / 2 ))         # move to the next place
  done

  echo "$result"
}

# ---------------------------------------------------------------
# Binary -> decimal, done by hand: add up the places with a 1.
# ---------------------------------------------------------------
from_binary() {
  local bits=$1
  local total=0
  local length=${#bits}
  local place=$(( 1 << (length - 1) ))   # value of the leftmost place
  local i bit

  for (( i = 0; i < length; i++ )); do
    bit=${bits:i:1}
    if [[ $bit == 1 ]]; then
      total=$(( total + place ))
    fi
    place=$(( place / 2 ))                # next place is half as big
  done

  echo "$total"
}

# ---------------------------------------------------------------
# Split a bit string into groups of 4 so it is easier to read.
# ---------------------------------------------------------------
group_bits() {
  local bits=$1
  local out="" i
  for (( i = 0; i < ${#bits}; i += 4 )); do
    out="$out${bits:i:4} "
  done
  echo "${out% }"                         # drop the trailing space
}

# ---------------------------------------------------------------
# Print a number in all three forms, with the working shown.
# ---------------------------------------------------------------
show_all() {
  local n=$1
  local width bin
  width=$(bit_width "$n")
  bin=$(to_binary "$n" "$width")

  # list which places are on, e.g. "32 + 8 + 2"
  local parts=""
  local place=$(( 1 << (width - 1) ))
  while (( place >= 1 )); do
    if (( n & place )); then
      if [[ -n $parts ]]; then parts="$parts + "; fi
      parts="$parts$place"
    fi
    place=$(( place / 2 ))
  done
  [[ -z $parts ]] && parts="0"

  echo "Decimal: $n"
  echo "Binary:  $(group_bits "$bin")   ($width bits)"
  printf "Hex:     0x%0$(( width / 4 ))X\n" "$n"
  echo "Places:  $parts"
}

# ---------------------------------------------------------------
# Show each character of some text as an ASCII byte.
# ---------------------------------------------------------------
show_text() {
  local text=$1
  local i ch code

  printf '%-6s %-4s %-9s %s\n' "Char" "Dec" "Binary" "Hex"
  for (( i = 0; i < ${#text}; i++ )); do
    ch=${text:i:1}
    code=$(printf '%d' "'$ch")          # character -> ASCII number
    if (( code > 255 )); then
      printf '%-6s %s\n' "$ch" "(not plain ASCII)"
      continue
    fi
    [[ $ch == " " ]] && ch="space"
    printf '%-6s %-4s %-9s 0x%02X\n' "$ch" "$code" "$(to_binary "$code" 8)" "$code"
  done
}

usage() {
  cat <<'EOF'
binconv - convert between decimal, binary and hex (0 to 4294967295)

  binconv.sh 42            decimal input
  binconv.sh 0b101010      binary input
  binconv.sh 0x2A          hex input
  binconv.sh --text yeah   show text as ASCII bytes
  binconv.sh --help        show this help
EOF
}

die() {
  echo "Error: $1" >&2
  echo "Run with --help to see examples." >&2
  exit 1
}

too_big() {
  die "$1 is too big. This tool handles 0 to $MAX (32 bits)."
}

# ---------------------------------------------------------------
# Main: decide what kind of input we were given.
# ---------------------------------------------------------------
input=$1

if [[ -z $input ]]; then
  usage
  exit 1
fi

case $input in
  -h|--help)
    usage
    exit 0
    ;;

  -t|--text)
    shift
    [[ -z $* ]] && die "give some text after --text, like: --text yeah"
    show_text "$*"
    exit 0
    ;;

  0b*|0B*)
    bits=${input:2}
    [[ $bits =~ ^[01]+$ ]] || die "'$input' is not valid binary. Use only 0s and 1s after 0b."
    (( ${#bits} <= MAX_BITS )) || too_big "$input"
    number=$(from_binary "$bits")
    ;;

  0x*|0X*)
    digits=${input:2}
    [[ $digits =~ ^[0-9a-fA-F]+$ ]] || die "'$input' is not valid hex. Use 0-9 and A-F after 0x."
    (( ${#digits} <= 8 )) || too_big "$input"     # 8 hex digits = 32 bits
    number=$(( 16#$digits ))
    ;;

  *)
    [[ $input =~ ^[0-9]+$ ]] || die "'$input' is not a number. Use a decimal number, 0b..., or 0x..."
    (( ${#input} <= 10 )) || too_big "$input"     # stop huge numbers before doing math on them
    number=$(( 10#$input ))   # 10# stops a leading 0 from meaning octal
    ;;
esac

(( number <= MAX )) || too_big "$number"

show_all "$number"