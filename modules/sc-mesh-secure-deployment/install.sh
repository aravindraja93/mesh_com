#!/bin/bash

# Check if command(s) exists and fail otherwise.
function command_exists {
  for cmd in $1; do
    echo -n "> Checking $cmd installed... "
    INSTALLED=($(apt -qq list $cmd 2>/dev/null | awk -F[ '{print $2}'))
    if $INSTALLED &> /dev/null; then
      echo "FALSE"
      echo "> Installing..."
      sudo apt-get install -y -qq $cmd --no-install-recommends
      echo ""
    else
      echo "TRUE"
    fi
  done
}

function menu_from_array()
{
  select choice; do
  # Check the selected menu item number
  if [ 1 -le "$REPLY" ] && [ "$REPLY" -le $# ];
  then
  break;
  else
  echo "Wrong selection: Select any number from 1-$#"
  fi
  done
}

# TODO: This isn't used. Might be useful in future? It can gather dust here.
function rename_interfaces {
inf_arr=($(ip -o link | awk '$2 ~ "wl" && $2 !~ "wlan"  {print substr($2, 1, length($2)-1) "," $(NF-2)}'))
COUNTER=2
for i in "${inf_arr[@]}"
do
inf_arr=($(sed -r 's/,/\n/g' <<< $inf_arr))
inf_name=${inf_arr[0]}
inf_mac=${inf_arr[1]}
ip link set $inf_name down
echo "Renaming dev $inf_name to wlan$COUNTER (mac=$inf_mac) and adding to /etc/udev/rules.d/70-persistent-net.rules"
COUNTER=$(( COUNTER + 1 ))
cat <<EOF > /etc/udev/rules.d/70-persistent-net.rules
SUBSYSTEM=="net", ACTION=="add", DRIVERS=="?*", ATTR{address}=="$inf_mac", ATTR{dev_id}=="0x0", ATTR{type}=="1", KERNEL=="wlan*", NAME="wlan$COUNTER"
EOF
sudo udevadm control --reload-rules && udevadm trigger --type=devices --action=add
ip link set wlan$COUNTER up
done
}

# TODO: This is the same function as the one in configure.sh - remove one.
function ap_connect {
echo '> Connecting to Access Point...'
read -p "- SSID: " ssid
read -p "- Password: " password
cat <<EOF > conf/ap.conf
network={
  ssid="$ssid"
  psk="$password"
}
EOF
echo '> Please choose from the list of available interfaces...'
interfaces_arr=($(ip link | awk -F: '$0 !~ "lo|vir|doc|eth|bat|^[^0-9]"{print $2}'))
menu_from_array "${interfaces_arr[@]}"
sudo wpa_supplicant -B -i $choice -c conf/ap.conf
sudo dhclient -v $choice
}

#-----------------------------------------------------------------------------#
# Main Script
#-----------------------------------------------------------------------------#
echo '> Allow ssh and turn on netmanager so we can connect to this node...'
sudo ufw allow ssh
sudo nmcli networking on
# Connect to AP
read -p "> We MUST be on the same network as the Server. Connect to AP? (Y/N): " confirm
if [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]]; then
  ap_connect
fi
# Provision the node with required packages
echo "> Checking required packages..."
command_exists "git make python3-pip batctl ssh clang libssl-dev net-tools \
                iperf3 avahi-daemon avahi-dnsconfd avahi-utils libnss-mdns \
                bmon isc-dhcp-server alfred batctl resolvconf"
# Clone this repo
echo "> Cloning..."
git clone https://github.com/tiiuae/mesh_com.git
if [ $? -ne 0 ]; then
    echo "ERROR: Couldn't clone the git repo! Exiting.."
    exit 0
fi
echo "> Init submodules..."
cd mesh_com
#git submodule update --init --recursive
git submodule update --init common/security/cryptolib
