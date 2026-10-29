# Digital Doorbell
Designed by Joppe Koers in september 2022

## Description
This project is a video doorbell system that shows users who is at the front door and allows them to open it.\
This system consists of a touchscreen computer that runs headless
- `Debian` with  a=
- `xinit` window manager, that runs a
- `C++17` application with a frontend in
- `ImGui` with a
- `OpenCV3` backend.\
When the user selects a name to call the C++ application calls a
- `docker` container that runs a
- `asterisk` `SIP` server, and uses asterisk's
- `originate` command to make the front door camera
- `AXIS A8105-E` call a the selected client's
- `IP video phone` model:
- `Fanvil_I53W`\
This happens over a local network that is not connected to the outside internet
The `touchscreen computer` runs a
- `DHCP` server that manages the local network's IP addresses, and assigns a
- `static IP` to itself.\
A user can also call a second SIP camera in the hallway powered by a
- `Raspberry Pi 3` that runs a
- `linphone` SIP client.\
The system also supports
- `calling between users`
See `doc/notes.md` for more information.

## Changing apartment occupant(s) (names)
1. Connect a computer to the `PoE switch`
2. ssh into the `touchscreen computer`: `ssh root@192.168.2.18`
3. Edit the occupants config file: `nano /root/video-doorbell/app/occupants.conf`
	See `/root/video-doorbell/app/occupants.example.conf` for how to configure it
4. Run `/root/video-doorbell/production.sh` to load the config file, watch the output, it will tell you if you've not formatted the file correctly
5. Validate that the app has started correctly by making a test call

### Get a list connected `indoor stations` and their IPs
1. ssh into the `touchscreen computer` as described above
2. run `asterisk -rx 'sip show peers'`

### Connecting to the cameras
The cameras are AXIS A8105-E door stations
1. ssh into the `touchscreen computer` as described above
2. run `asterisk -rx 'sip show peers'`
3. Open `http://<ip>` in Firefox (other browsers don't work), login `root` / `joppe2022`

### (Status) logs
```shell
# List connected devices
asterisk -rx 'sip show peers'
tail /var/log/asterisk/messages

# Copied from the cameras every 10 minutes.
tail /var/log/cameras/front-door.log
tail /var/log/cameras/hallway.log

tail /root/video-doorbell/app/out.log
# List of all calls
tail /var/log/asterisk/cdr-csv/Master.csv
```

## Giving the `touchscreen computer` internet access
The local network has no internet. To get internet on the `touchscreen computer` (for `apt install`, etc.), share your laptop's wifi over its ethernet port.

1. On the Mac: System Settings -> General -> Sharing -> Internet Sharing. Share from `Wi-Fi` to the ethernet adapter. The Mac becomes `192.168.2.1` on the doorbell network.
2. Connect the Mac to the `PoE switch`
3. `ssh root@192.168.2.18` and check with `ping 1.1.1.1`

Nothing needs to be done on the `touchscreen computer`: `/etc/netplan/00-installer-config.yaml` has a static IP, a default route via `192.168.2.1` and public DNS. When no laptop is sharing, the route simply leads nowhere and the doorbell keeps working offline.
```yaml
network:
  version: 2
  ethernets:
    enp3s0:
      dhcp4: false
      addresses: [192.168.2.18/24]
      routes:
        - to: default
          via: 192.168.2.1
      nameservers:
        addresses: [1.1.1.1, 8.8.8.8]
    enp4s0:
      dhcp4: true
      optional: true
```
After editing that file run `netplan apply`.

Note: Internet Sharing on the Mac runs its own DHCP server next to the `touchscreen computer`'s `isc-dhcp-server`. Unplug the Mac when done so the `indoor stations` don't get leases from it.

## Components
Why these components? Because they had already been bought, so I might as well use them.\
This project uses names like `indoor Station` throughout, this is a list of what those devices are referring to.
- FABS-810P/G(H)			`touchscreen computer`
- AXIS A8105-E 				network	video door station / `front door camera`
- AXIS A8105-E 				network	video door station / `hallway camera`
- Raspberry Pi 2B			linphone camera / `rpi camera`
- Fanvil_I53W				ip phone / `indoor station`
- HP 2520-24-PoE 28 port	managed `network switch`
