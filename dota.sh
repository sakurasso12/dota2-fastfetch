#!/usr/bin/env bash
# Prints one line of the Dota-style info block for fastfetch: dota.sh <line number>
# The whole block is wrapped in big red brackets, so every line is padded to the same width.
# Works on any Linux: CPU/GPU names come from fastfetch itself, the Hero colour follows the distro.

# ---------- your Dota 2 rank ----------
# Herald / Guardian / Crusader / Archon / Legend / Ancient / Divine / Immortal + stars I-V
RANK_MEDAL="Archon"
RANK_STARS="V"

DIR=$(cd "$(dirname "$0")" && pwd)
R=$'\e[1;38;2;194;60;42m'   # red (keys and brackets)
N=$'\e[0m'

# ---------- hardware (cached: it does not change between terminal launches) ----------
cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/dota-fastfetch"
cache="$cache_dir/hw"
if [[ ! -s $cache || -n $(find "$cache" -mmin +1440 2>/dev/null) ]]; then
  mkdir -p "$cache_dir"
  tmp=$(mktemp "$cache_dir/hw.XXXXXX")
  fastfetch -c "$DIR/dota-hw.jsonc" --pipe true 2>/dev/null > "$tmp" && mv "$tmp" "$cache" || rm -f "$tmp"
fi

clean_cpu() {
  sed -E 's/\((R|r|TM|tm)\)//g; s/ CPU//; s/ @.*//; s/ [0-9]+-Core( Processor)?//;
          s/ Processor//; s/ (with|w\/) Radeon.*//; s/ +/ /g; s/^ //; s/ $//'
}

cpu=$(grep -m1 '^CPU|' "$cache" 2>/dev/null | cut -d'|' -f2- | clean_cpu)
# prefer a discrete GPU (gaming laptops have integrated + discrete)
gpu_line=$(grep '^GPU|Discrete|' "$cache" 2>/dev/null | head -1)
[[ -z $gpu_line ]] && gpu_line=$(grep -m1 '^GPU|' "$cache" 2>/dev/null)
gpu_vendor=$(cut -d'|' -f3 <<< "$gpu_line")
gpu_name=$(cut -d'|' -f4- <<< "$gpu_line")
if [[ $gpu_name == "$gpu_vendor"* ]]; then gpu="$gpu_name"; else gpu="$gpu_vendor $gpu_name"; fi
gpu=$(sed -E 's/ +/ /g; s/^ //; s/ $//' <<< "$gpu")

[[ -z $cpu ]] && cpu="Unknown"
[[ -z $gpu ]] && gpu="Unknown"

# ---------- live values ----------
os_id=$(. /etc/os-release 2>/dev/null && echo "$ID")
os=$(. /etc/os-release 2>/dev/null && echo "$NAME")
[[ -z $os ]] && os=$(uname -s)
mem=$(awk '/MemTotal/{t=$2} /MemAvailable/{a=$2} END{u=t-a; printf "%.2f GiB / %.2f GiB (%d%%)", u/1048576, t/1048576, u*100/t}' /proc/meminfo)
match="$(( $(cut -d. -f1 /proc/uptime) / 60 )) Min"

keys=("Hero:" "Rank:" "" "Intelligence:" "Agility:" "Strength:" "" "Match:" "" "BAR")
vals=("$os" "$RANK_MEDAL${RANK_STARS:+ $RANK_STARS}" "" "$cpu" "$mem" "$gpu" "" "$match" "" "")
last=$(( ${#keys[@]} - 1 ))

# gradient TEXT R1 G1 B1 R2 G2 B2 -> text coloured letter by letter from colour 1 to colour 2
gradient() {
  local t=$1 n=${#1} out="" j r g b
  for (( j=0; j<n; j++ )); do
    r=$(( $2 + ($5 - $2) * j / (n > 1 ? n - 1 : 1) ))
    g=$(( $3 + ($6 - $3) * j / (n > 1 ? n - 1 : 1) ))
    b=$(( $4 + ($7 - $4) * j / (n > 1 ? n - 1 : 1) ))
    out+=$'\e[1;38;2;'"$r;$g;$b"'m'"${t:$j:1}"
  done
  printf '%s' "$out$N"
}

# Hero: distro name in the distro's own colours (light -> dark)
case $os_id in
  arch)         hero_grad=(140 220 255  23 105 209) ;;  # Arch blue
  ubuntu)       hero_grad=(255 170 120 220  72  20) ;;  # Ubuntu orange
  debian)       hero_grad=(255 120 150 168   0  48) ;;  # Debian red
  fedora)       hero_grad=(130 180 255  41  65 114) ;;  # Fedora blue
  linuxmint)    hero_grad=(190 240 150  90 160  40) ;;  # Mint green
  manjaro)      hero_grad=( 90 230 150  20 150  80) ;;  # Manjaro green
  opensuse*)    hero_grad=(150 230 120  60 150  40) ;;  # openSUSE green
  endeavouros)  hero_grad=(200 160 255 120  60 200) ;;  # EndeavourOS purple
  pop)          hero_grad=(110 220 230  40 150 170) ;;  # Pop!_OS teal
  cachyos)      hero_grad=(120 240 220  20 160 140) ;;  # CachyOS teal
  nixos)        hero_grad=(160 200 255  80 120 200) ;;  # NixOS blue
  gentoo)       hero_grad=(210 200 255 110  90 180) ;;  # Gentoo purple
  *)            hero_grad=(235 235 235 140 140 140) ;;  # anything else: white -> grey
esac
hero_disp=$(gradient "$os" "${hero_grad[@]}")

# Match: lavender -> lilac
match_disp=$(gradient "$match" 215 195 255 165 110 235)

# Rank: medal name in the medal's colours (light -> dark), stars in muted yellow, not bold
# (terminals have no text opacity, so the yellow is desaturated/darkened instead)
case $RANK_MEDAL in
  Herald)   rank_grad=(200 170 130 120  85  50) ;;
  Guardian) rank_grad=(210 215 220 110 120 130) ;;
  Crusader) rank_grad=(220 200 140  80 140 120) ;;
  Archon)   rank_grad=(185 192 196  70 155 110) ;;  # silver-grey -> green
  Legend)   rank_grad=(235 215 140 120 150  80) ;;
  Ancient)  rank_grad=(160 230 220  30 140 150) ;;
  Divine)   rank_grad=(255 230 150 200 150  40) ;;
  Immortal) rank_grad=(255 200 150 190  50  40) ;;
  *)        rank_grad=(235 235 235 140 140 140) ;;
esac
rank_disp="$(gradient "$RANK_MEDAL" "${rank_grad[@]}")"
[[ -n $RANK_STARS ]] && rank_disp+=$' \e[22;38;2;196;178;110m'"$RANK_STARS$N"

# Dota attribute colours for Intelligence / Agility / Strength:
# the whole line (key + value) goes from a light to a dark shade of the attribute colour
INT_GRAD=(170 225 255  30 110 215)   # light blue -> blue
AGI_GRAD=(160 240 170  30 140  60)   # light green -> dark green
STR_GRAD=(255 160 145 170  40  30)   # light red -> dark red

keyw=13   # length of "Intelligence:"
width=0
for i in "${!keys[@]}"; do
  len=$(( keyw + 1 + ${#vals[$i]} ))
  (( len > width )) && width=$len
done

i=$1
if [[ ${keys[$i]} == BAR ]]; then
  bar=""
  for c in "194;60;42" "140;35;25" "90;20;14" "45;12;9" "15;15;15"; do
    bar+=$'\e[38;2;'"$c"'m███'
  done
  plain=15
  content="$bar$N"
elif [[ -z ${keys[$i]} ]]; then
  plain=0; content=""
else
  printf -v k "%-${keyw}s" "${keys[$i]}"
  plain=$(( keyw + 1 + ${#vals[$i]} ))
  v=${vals[$i]}
  case $i in
    0) content="$R$k$N $hero_disp" ;;
    1) content="$R$k$N $rank_disp" ;;
    3) content=$(gradient "$k $v" "${INT_GRAD[@]}") ;;
    4) content=$(gradient "$k $v" "${AGI_GRAD[@]}") ;;
    5) content=$(gradient "$k $v" "${STR_GRAD[@]}") ;;
    7) content="$R$k$N $match_disp" ;;
    *) content="$R$k$N $v" ;;
  esac
fi

case $i in
  0)       l="⎡"; r="⎤" ;;
  "$last") l="⎣"; r="⎦" ;;
  *)       l="⎢"; r="⎥" ;;
esac

printf "%s%s%s %s%*s %s%s%s\n" "$R" "$l" "$N" "$content" $(( width - plain )) "" "$R" "$r" "$N"
