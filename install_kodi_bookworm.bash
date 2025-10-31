#!/bin/bash
user=$(logname)
codename=$(cat /etc/os-release | grep ^VERSION= | cut -d'(' -f2 | cut -d')' -f1)
architecture=$(dpkg --print-architecture)

#sudo apt update && sudo apt dist-upgrade -y && sudo reboot

#install video driver
apt-get install -y libgl1-mesa-dri mesa-utils

apt-get install -y kodi21 kodi21-eventclients-kodi-send
export PYTHONPATH=/usr/lib/python3.11/site-packages/kodi

#create kodi.service
cat > /etc/systemd/system/kodi.service << EOF
[Unit]
Description = Kodi Media Center
# if you don't need the MySQL DB backend, this should be sufficient
#After = systemd-user-sessions.service networ.target sound.target pulseaudio.service pulseaudio.socket

# After = systemd-user-sessions.service network.target sound.target
# if you need the MySQL DB backend, use this block instead of the previous
After = systemd-user-sessions.service network.target sound.target mysql.service
Wants = mysql.service

[Service]
ExecStartPre=+setcap 'cap_net_bind_service=+ep' /usr/lib/aarch64-linux-gnu/kodi/kodi.bin
User = $user
#Group = input
Type = simple
ExecStart = /usr/bin/kodi --standalone
#Restart = always
Restart = on-abort
RestartSec = 15

[Install]
WantedBy = multi-user.target
EOF

#download mediathek addon
wget https://github.com/rols1/Kodi-Addon-ARDundZDF/releases/latest/download/Kodi-Addon-ARDundZDF.zip

#download TV Sender
wget https://raw.githubusercontent.com/jnk22/kodinerds-iptv/master/iptv/kodi/kodi_tv.m3u

systemctl daemon-reload
systemctl enable kodi.service
systemctl start kodi.service
#systemctl stop kodi.service

#wait for kodi to be install/setup complete
while ! [ -d "/home/$user/.kodi/userdata/" ]
do
	echo -n ". "
	sleep 2
done
echo ""

#install/modity Kodi all this injections need a restart of the service/kodi/pi to get this to take action
#create advancedsettings
cat > /home/$user/.kodi/userdata/advancedsettings.xml << EOF
<advancedsettings version="1.0">
	<cputempcommand>/bin/sed -e 's/\([0-9]*\)[0-9]\{3\}.*/\1 C/' /sys/class/thermal/thermal_zone0/temp</cputempcommand>
	<gputempcommand>vcgencmd measure_temp | /bin/sed -e "s/temp=//" -e "s/\..*'/ /"</gputempcommand>
</advancedsettings>
EOF

send_delay=250
echo "pause for 30 seconds for kodi to startup"
sleep 30

kodi-send -a "InhibitScreensaver(true)"

#enable version check
kodi-send -a "SetFocus(11)" -d $send_delay
kodi-send -a "Action(Select)" -d $send_delay
kodi-send -a "SetFocus(28)" -d $send_delay
kodi-send -a "Action(Select)" -d $send_delay

#enable service webinterface & json on port 80
kodi-send -a "ActivateWindow(10018)" -d $send_delay
kodi-send -a "SetFocus(-199)" -d $send_delay
kodi-send -a "SetFocus(-177)" -d $send_delay
kodi-send -a "Action(Select)" -d $send_delay

kodi-send -a "SetFocus(11)" -d $send_delay
kodi-send -a "Action(Select)" -d $send_delay

kodi-send -a "SetFocus(-179)" -d $send_delay
kodi-send -a "Action(Select)" -d $send_delay

kodi-send -a "SetFocus(11)" -d $send_delay
kodi-send -a "Action(Select)" -d $send_delay

kodi-send -a "SetFocus(-178)" -d $send_delay
kodi-send -a "Action(Backspace)" -d $send_delay
kodi-send -a "Action(Backspace)" -d $send_delay
kodi-send -a "ActivateWindow(10000)"

#install chorus webinterface
kodi-send -a "InstallAddon(webinterface.chorus)" -d $send_delay
kodi-send -a "SetFocus(11)" -d $send_delay
kodi-send -a "Action(Select)" -d $send_delay

kodi-send -a "Notification(Please wait,Just 60 seconds,60000))"
#read -n 1 -s -r -p "Press any key to continue"

sleep 60

kodi-send -a "ActivateWindow(10018)" -d $send_delay
kodi-send -a "SetFocus(-199)" -d $send_delay

kodi-send -a "SetFocus(-173)" -d $send_delay
kodi-send -a "Action(Select)" -d $send_delay

kodi-send -a "Action(UP)" -d $send_delay
kodi-send -a "Action(Select)" -d $send_delay
kodi-send -a "ActivateWindow(10000)"

apt-get install -y kodi21-vfs-rar kodi21-vfs-libarchive kodi21-pvr-iptvsimple kodi21-inputstream-adaptive kodi21-inputstream-ffmpegdirect

#kodi-send -a "RestartApp"
systemctl restart kodi.service
sleep 30

window_id=-1

echo "enter loop"
while [[ $window_id != 10000 ]]
do
  window_id=$(curl -s http://localhost/jsonrpc -H 'Content-Type: application/json' -d '{"jsonrpc":"2.0","method":"GUI.GetProperties","params":{"properties":["currentwindow"]},"id":1}')
  window_id=$(echo $window_id | cut -d: -f6 | cut -d, -f1)
  echo $window_id

  case $window_id in
  10100)
        kodi-send -a "SetFocus(11)" -d $send_delay
        kodi-send -a "Action(Select)" -d $send_delay
        sleep 0.5
        ;;
  10140)
        sleep 0.5
        kodi-send -a "SetFocus(28)" -d $send_delay
        kodi-send -a "Action(Select)" -d $send_delay
        sleep 0.5
        ;;
  12000)
        kodi-send -a "SetFocus(7)" -d $send_delay
        kodi-send -a "Action(Select)" -d $send_delay
        sleep 0.5
        ;;
  esac
done
