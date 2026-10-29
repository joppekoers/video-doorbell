#!/bin/sh
# Pulls the system log out of each camera and appends the new lines to /var/log/cameras/<name>.log.
# The cameras (firmware 1.65) cannot send their log to a syslog server and only keep a few
# hundred lines, so this runs from cron every 10 minutes (see doc/installation.md).

OUT=/var/log/cameras
# 400 MB per camera, so the two logs together stay well under 1 GB.
MAX_BYTES=419430400
mkdir -p "$OUT"

fetch() {
	name=$1
	sip_peer=$2
	# The cameras get their IP from DHCP, so ask Asterisk where the camera registered from.
	ip=$(asterisk -rx "sip show peers" | awk -v peer="$sip_peer/$sip_peer" '$1 == peer {print $2}')
	[ -n "$ip" ] || return
	curl -s --digest -u root:joppe2022 --max-time 15 "http://$ip/axis-cgi/admin/systemlog.cgi" | grep '^20' > "$OUT/$name.new"
	[ -s "$OUT/$name.new" ] || return

	# Only the lines we haven't seen in the previous fetch are new.
	if [ -f "$OUT/$name.prev" ]; then
		grep -vxF -f "$OUT/$name.prev" "$OUT/$name.new" >> "$OUT/$name.log"
	else
		cat "$OUT/$name.new" >> "$OUT/$name.log"
	fi
	mv "$OUT/$name.new" "$OUT/$name.prev"

	if [ "$(stat -c %s "$OUT/$name.log")" -gt "$MAX_BYTES" ]; then
		# Keep the newest half, dropping the partial first line.
		tail -c $((MAX_BYTES / 2)) "$OUT/$name.log" | sed 1d > "$OUT/$name.tmp" && mv "$OUT/$name.tmp" "$OUT/$name.log"
	fi
}

fetch front-door 7004
fetch hallway 7006
