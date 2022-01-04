# /bin/bash

# This is the script for the secure OS

# Step 1 would be to set the eth0 or wlan0 depending on what the case is 

# create the supplicant file; in this case it called supplicant

function help {
    echo "       ./mesh_script   to run the script"
    echo "       -restart        restart the docker"
    echo "       -log            show the log file"
    echo "       -help           this help menu"
    echo ""
    exit 1
}

function create_LogFile {
LOGFILE=/var/log/mesh_settings.log

touch $LOGFILE
}


function connect_to_WiFi {
    cat /sys/class/net/eth0/operstate | grep 'up'
    if [echo $?];
    then
    echo "eth0 interface is up,  wlan0 is up" >> $LOGFILE
    killall wpa_supplicant
    ifconfig eth0 down
    ifconfig wlan0 down
    ifconfig wlano up
    echo "restarting wlan0 and killing eth0 to not get any issues"
    #touch supplicant.conf
    cat << EOT > /etc/wpa_supplicant.conf
    ctrl_interface=/var/run/wpa_supplicant
    ap_scan=1
    country=AD

    network={
        ssid="WirelessLab"
        psk="ssrcdemo"
        }
EOT

    adev=$(iw dev |wc -l)

    if [ "$adev" == 7 ]; then
    echo mmc1:0001:2 > /sys/bus/sdio/drivers/brcmfmac/bind
    fi

    echo " Waiting for the connection\n "
    echo " Waiting to fully establish the connection" >> $LOGFILE
    wpa_supplicant -c supplicant.conf -i wlan0 -B

    sleep 7

    a=$(iwconfig wlan0 2> /dev/null | awk -F\" '{print $2}')

    while [["$a" != "WirelessLab"]]
    do
    echo "Waiting to be connected to WirelessLab" >> $LOGFILE
    sleep 2
    done

    echo "Connected to WirelessLab!" >> $LOGFILE
    fi
}
#Give it then an IP address with udhcpc
function Give_IP {
    udhcpc -i wlan0
    sleep 5
    echo "IP Address assigned" >> $LOGFILE

    echo "To check that it is in the routing table" >> $LOGFILE

    cat route -n >> $LOGFILE


#if [["$a" == "WirelessLab"]];
#then
#echo "yes"
#echo "Connected to WirelessLab" >> $LOGFILE
#else echo "Not connected to WirelessLab" >> $LOGFILE
#fi
}

#Then we need to enable SSH
function Enable_SSH {

cat <<EOT >> /etc/ssh/sshd_config
PermitRootLogin yes
PubkeyAuthentication yes
PasswordAuthentication yes
EOT
sleep 2

/etc/init.d/S50sshd start

echo "SSH services have been started" >> $LOGFILE

}

function set_Data_DNS {
    date --set="1 JAN 2022 14:19:00"

    #set dns
    echo 'nameserver 8.8.8.8' > /etc/resolv.conf

    echo "Added the nameserver to /etc/resolv.conf" >>$LOGFILE


    #set correct date
    #echo '> Type the current date (format: YYYY-MM-DD)'
    #read -p "- Date: " date
    #echo '> Type the current time (format: HH:MM:SS)'
    #read -p "- Time: " ctime

    #date -s "$date $ctime"

    #verify if wlan0 (onboard is working)
}

function start {

    git clone git://github.com/tiiuae/mesh_com
    cd mesh_com
    git checkout develop

    cd modules/utils/docker/
    ./start-docker.sh
}
#restart docker

function restart {
    dockervar=$(ls /etc/init.d/ |grep docker)

    /etc/init.d/$dockervar stop
    sleep 2
    /etc/init.d/$dockervar start

    docker run -it --privileged --net="host" -rm seccomms /bin/bash
}

#Enter as a parameter to show the log file
function log {
    cat /var/log/mesh_settings.log
}

while (( "$#")); do
    if [ $# -eq 0 ]
    then
        create_LogFile
        connect_to_WiFi
        Give_IP
        Enable_SSH
        set_Data_DNS
        start
    fi
    case "$1" in
     -restart)
        restart
        ;;
     -log)
        log
        ;;
     -help)
        help
        ;;
     *)
        echo "do ./mesh_script.sh -help to to know how to run the script"
        ;;
    esac
done