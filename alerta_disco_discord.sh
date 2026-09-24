#!/bin/bash

MODE="${1:-watch}"

VM_NAME=$(hostname)

THRESHOLD=95
DELTA_WHILE_CRIT=1

STATE_DIR="/var/lib/disk-alert"
STATE_FILE="${STATE_DIR}/state.db"
LOCK_FILE="/var/run/disk-alert.lock"

# A URL abaixo é preenchida dinamicamente pelo Ansible
DISCORD_URL="xxxx"

PARTITIONS=(
    "/"
    "/emails"
    "/mysql"
)


mkdir -p "$STATE_DIR"
touch "$STATE_FILE"

exec 9>"$LOCK_FILE"
flock -n 9 || exit 0

NOW=$(date +%s)

get_previous_usage() {
    grep "^$1|" "$STATE_FILE" | cut -d'|' -f2
}

get_last_alert_time() {
    grep "^$1|" "$STATE_FILE" | cut -d'|' -f3
}

update_state() {
    grep -v "^$1|" "$STATE_FILE" > "${STATE_FILE}.tmp"
    echo "$1|$2|$3" >> "${STATE_FILE}.tmp"
    mv "${STATE_FILE}.tmp" "$STATE_FILE"
}

send_discord() {
    local message="$1"

    /usr/bin/curl -s -H "Content-Type: application/json" \
        -X POST \
        -d "{\"content\": \"$message\"}" \
        "$DISCORD_URL" > /dev/null
}

ALERT_BODY=""

for part in "${PARTITIONS[@]}"
do
    if ! /usr/bin/df -hP "$part" >/dev/null 2>&1; then
        continue
    fi

    DATA=$(/usr/bin/df -hP "$part" | tail -1)

    TOTAL=$(echo "$DATA" | awk '{print $2}')
    USED=$(echo "$DATA" | awk '{print $3}')
    PERCENT=$(echo "$DATA" | awk '{print $5}' | tr -d '%')

    PREVIOUS=$(get_previous_usage "$part")
    LAST_ALERT=$(get_last_alert_time "$part")

    [ -z "$PREVIOUS" ] && PREVIOUS=$PERCENT
    [ -z "$LAST_ALERT" ] && LAST_ALERT=0

    DELTA=$((PERCENT - PREVIOUS))

    SEND_ALERT=0
    EXTRA_LINE=""

    # =========================
    # MODO REPORT (08h / 20h)
    # =========================
    if [ "$MODE" = "report" ]; then
        if [ "$PERCENT" -ge "$THRESHOLD" ]; then
            SEND_ALERT=1
        fi

    # =========================
    # MODO WATCH (tempo real)
    # =========================
    else
        if [ "$PERCENT" -ge "$THRESHOLD" ] && [ "$DELTA" -ge "$DELTA_WHILE_CRIT" ]; then
            SEND_ALERT=1
            EXTRA_LINE="📈 **Aumento de uso desde a última checagem:** ${DELTA}%"
        fi
    fi

    if [ "$SEND_ALERT" -eq 1 ]; then
        ALERT_BODY+="📌 **Partição:** ${part}\n"
        ALERT_BODY+="📊 **Uso:** ${PERCENT}% (${USED} de ${TOTAL})\n"

        if [ -n "$EXTRA_LINE" ]; then
            ALERT_BODY+="${EXTRA_LINE}\n"
        fi

        ALERT_BODY+="\n"

        update_state "$part" "$PERCENT" "$NOW"
    else
        update_state "$part" "$PERCENT" "$LAST_ALERT"
    fi
done

if [ -n "$ALERT_BODY" ]; then
    SEPARATOR="================================================================="
    MESSAGE="${SEPARATOR}\nALERTA DE DISCO....\n⚠️ **ALERTA DE DISCO: ${VM_NAME}**\n\n${ALERT_BODY}"

    send_discord "$MESSAGE"
fi
