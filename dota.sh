#!/usr/bin/env bash
# Prints one line of the Dota-style info block for fastfetch: dota.sh <line number>
# The whole block is wrapped in big red brackets, so every line is padded to the same width.

R=$'\e[1;38;2;194;60;42m'   # red (keys and brackets)
N=$'\e[0m'

os=$(. /etc/os-release && echo "$NAME")
cpu=$(grep -m1 'model name' /proc/cpuinfo | sed -E 's/.*: //; s/\((R|TM)\)//g; s/ CPU.*//; s/ @.*//; s/ +/ /g')
gpu=$(lspci 2>/dev/null | grep -m1 -iE 'vga|3d controller' | sed -E 's/.*: ([A-Za-z]+)[^[]*\[([^]]+)\].*/\1 \2/')
mem=$(awk '/MemTotal/{t=$2} /MemAvailable/{a=$2} END{u=t-a; printf "%.2f GiB / %.2f GiB (%d%%)", u/1048576, t/1048576, u*100/t}' /proc/meminfo)
match="$(( $(cut -d. -f1 /proc/uptime) / 60 )) Min"

keys=("Hero:" "Rank:" "" "Intelligence:" "Agility:" "Strength:" "" "Match:" "" "BAR")
vals=("$os" "Archon V" "" "$cpu" "$mem" "$gpu" "" "$match" "" "")
last=$(( ${#keys[@]} - 1 ))

# Archon medal colours: silver-grey -> green, one colour step per letter; "V" muted yellow
# (terminals have no text opacity, so the yellow is desaturated/darkened instead)
rank_plain="Archon V"
rank_colors=("185;192;196" "160;178;178" "135;170;158" "110;165;140" "85;160;122" "70;155;110" "0;0;0" "196;178;110")
rank_disp=""
for (( j=0; j<${#rank_plain}; j++ )); do
  weight=1; (( j == ${#rank_plain} - 1 )) && weight=22   # "V": muted yellow, not bold
  rank_disp+=$'\e['"$weight"';38;2;'"${rank_colors[$j]}"'m'"${rank_plain:$j:1}"
done
rank_disp+=$N

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
# Hero: Arch Linux in Arch colours, light blue -> Arch blue
hero_disp=$(gradient "$os" 140 220 255 23 105 209)
# Match: lavender -> lilac
match_disp=$(gradient "$match" 215 195 255 165 110 235)

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
  kc=$R
  case $i in
    0) v=$hero_disp ;;
    1) v=$rank_disp ;;
    7) v=$match_disp ;;
  esac
  case $i in
    3) content=$(gradient "$k $v" "${INT_GRAD[@]}") ;;
    4) content=$(gradient "$k $v" "${AGI_GRAD[@]}") ;;
    5) content=$(gradient "$k $v" "${STR_GRAD[@]}") ;;
    *) content="$kc$k$N $v" ;;
  esac
fi

case $i in
  0)       l="⎡"; r="⎤" ;;
  "$last") l="⎣"; r="⎦" ;;
  *)       l="⎢"; r="⎥" ;;
esac

printf "%s%s%s %s%*s %s%s%s\n" "$R" "$l" "$N" "$content" $(( width - plain )) "" "$R" "$r" "$N"
