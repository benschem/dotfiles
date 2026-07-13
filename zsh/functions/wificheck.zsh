## Report current Wi-Fi signal quality and connectivity (macOS)
function wificheck {
  local count=${1:-10}
  local info gw

  info=$(system_profiler SPAirPortDataType 2>/dev/null | awk '/Current Network Information:/,/Other Local Wi-Fi Networks:/')
  gw=$(route -n get default 2>/dev/null | awk '/gateway:/{print $2}')

  if [[ -z "$info" ]]; then
    echo "Not connected to Wi-Fi."
    return 1
  fi

  local ssid phy channel signal noise txrate snr
  ssid=$(echo "$info" | sed -n '2s/^[[:space:]]*\(.*\):$/\1/p')
  phy=$(echo "$info" | sed -n 's/.*PHY Mode: //p')
  channel=$(echo "$info" | sed -n 's/.*Channel: //p')
  signal=$(echo "$info" | awk '/Signal \/ Noise:/{print $4; exit}')
  noise=$(echo "$info" | awk '/Signal \/ Noise:/{print $7; exit}')
  txrate=$(echo "$info" | sed -n 's/.*Transmit Rate: //p')
  snr=$((signal - noise))

  local G=$'\e[32m' Y=$'\e[33m' R=$'\e[31m' N=$'\e[0m'
  local sig_c=$(_wificheck_rank $signal -60 -70)
  local noise_c=$(_wificheck_rank $noise -85 -80 1)
  local snr_c=$(_wificheck_rank $snr 30 20)

  echo "Wi-Fi diagnostics"
  echo "─────────────────"
  printf "%-10s %s\n" "SSID:" "$ssid"
  printf "%-10s %s\n" "PHY:" "$phy"
  printf "%-10s %s\n" "Channel:" "$channel"
  printf "%-10s ${sig_c}%s dBm${N}\n" "Signal:" "$signal"
  printf "%-10s ${noise_c}%s dBm${N}  (SNR: ${snr_c}%s dB${N})\n" "Noise:" "$noise" "$snr"
  printf "%-10s %s Mbps\n" "TX rate:" "$txrate"

  if [[ -z "$gw" ]]; then
    printf "\nNo default gateway — skipping ping tests.\n"
    return 0
  fi

  printf "\nPing tests (%d packets each)...\n\n" "$count"
  printf "%-10s %-8s %-12s %-12s\n" "Target" "Loss" "Avg (ms)" "Jitter (ms)"

  local t label host out loss loss_num stats avg jitter
  local loss_c avg_c jit_c avg_good avg_ok
  for t in "Gateway:$gw" "Internet:1.1.1.1"; do
    label=${t%%:*}
    host=${t#*:}
    out=$(ping -c $count -i 0.3 "$host" 2>/dev/null)
    loss=$(echo "$out" | awk '/packet loss/{print $(NF-2)}')
    stats=$(echo "$out" | awk -F'[=/ ]+' '/min\/avg/{print $7" "$9}')
    avg=${stats% *}
    jitter=${stats#* }

    loss_num=${loss%\%}
    loss_c=$(_wificheck_rank "${loss_num:-0}" 0 0.5 1)
    if [[ "$label" == "Gateway" ]]; then
      avg_good=3; avg_ok=10
    else
      avg_good=30; avg_ok=50
    fi
    avg_c=$(_wificheck_rank "${avg:-0}" $avg_good $avg_ok 1)
    jit_c=$(_wificheck_rank "${jitter:-0}" 3 10 1)

    printf "%-10s ${loss_c}%-8s${N} ${avg_c}%-12s${N} ${jit_c}%-12s${N}\n" \
      "$label" "${loss:-N/A}" "${avg:-N/A}" "${jitter:-N/A}"
  done

  printf "\n${G}good${N} / ${Y}fair${N} / ${R}poor${N}  (tuned for video calls & pair programming)\n"
  printf "  Signal   ≥-60 / ≥-70 dBm       Noise   ≤-85 / ≤-80 dBm\n"
  printf "  SNR      ≥30  / ≥20  dB        Loss    0%%   / ≤0.5%%\n"
  printf "  Jitter   ≤3   / ≤10  ms        Ping    ≤3/≤10 gw, ≤30/≤50 wan\n"
}

function _wificheck_rank {
  local v=$1 good=$2 ok=$3 reverse=${4:-0}
  local G=$'\e[32m' Y=$'\e[33m' R=$'\e[31m'
  if (( reverse )); then
    (( v <= good )) && { printf "$G"; return; }
    (( v <= ok ))   && { printf "$Y"; return; }
    printf "$R"
  else
    (( v >= good )) && { printf "$G"; return; }
    (( v >= ok ))   && { printf "$Y"; return; }
    printf "$R"
  fi
}
