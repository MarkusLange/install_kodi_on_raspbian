#!/bin/bash
user=$(logname)
group=$(id -gn $user)
home_path="/home/$user"

codename=$(cat /etc/os-release | grep ^VERSION= | cut -d'(' -f2 | cut -d')' -f1)
architecture=$(dpkg --print-architecture)

kodi_version=$(apt-cache policy kodi | head -3 | tail -1 | cut -d' ' -f4 | cut -d':' -f2 | cut -d'+' -f1)

whiptail --title "Installation Information" --no-button "Exit" --yesno \
"This script installs Kodi "$kodi_version" \n\
on "$codename" under user "$user"\n\
\n\
With:\n\
Archive support\n\
iptv simple\n\
add settings to show the temperatue of the pi correctly\n\
a webinterface of your choise\n\
and an systemd service for automatic startup" 15 60 3>&1 1>&2 2>&3

output=$?

case $output in
0)
	;;
1)
	exit;;
esac

#sudo apt update && sudo apt dist-upgrade -y && sudo reboot

#set cma memory to 512
#https://forums.raspberrypi.com/viewtopic.php?t=378418
#https://askubuntu.com/questions/537967/appending-to-end-of-a-line-using-sed
sed -i '/vc4-kms-v3d/ s/$/,cma-512/' /boot/firmware/config.txt

#install video driver
apt-get install -y libgl1-mesa-dri mesa-utils

case $codename in
bookworm)
	#install Kodi21 on bookworm
	apt-get install -y kodi21 kodi21-eventclients-kodi-send
	#https://discourse.coreelec.org/t/kodi-send-missing-module/53926/3
	export PYTHONPATH=/usr/lib/python3.11/site-packages/kodi
	;;
trixie)
	#install Kodi on trixie
	apt-get install -y kodi kodi-eventclients-kodi-send
	;;
esac

#create kodi.service
cat > /etc/systemd/system/kodi.service << EOF
[Unit]
Description = Kodi Media Center
# if you don't need the MySQL DB backend, this should be sufficient
# After = systemd-user-sessions.service networ.target sound.target pulseaudio.service pulseaudio.socket

# After = systemd-user-sessions.service network.target sound.target
# if you need the MySQL DB backend, use this block instead of the previous
After = systemd-user-sessions.service network.target sound.target mysql.service
Wants = mysql.service

[Service]
#ExecStartPre=+setcap 'cap_net_bind_service=+ep' /usr/lib/aarch64-linux-gnu/kodi/kodi.bin
AmbientCapabilities=CAP_NET_BIND_SERVICE
User = $user
#Group = input
Type = simple
#ExecStart = /usr/bin/kodi --standalone
ExecStart = /usr/bin/kodi-standalone
#Restart = always
Restart = on-abort
RestartSec = 15

[Install]
WantedBy = multi-user.target
EOF

case $codename in
bookworm)
	;;
trixie)
#https://forum.kodi.tv/showthread.php?tid=372513
cat > /etc/polkit-1/rules.d/50-power.rules << EOF
polkit.addRule(function(action, subject) {
    if ((action.id == "org.freedesktop.login1.reboot" ||
         action.id == "org.freedesktop.login1.reboot-multiple-sessions" ||
         action.id == "org.freedesktop.login1.power-off" ||
         action.id == "org.freedesktop.login1.power-off-multiple-sessions" ||
         action.id == "org.freedesktop.login1.suspend" ||
         action.id == "org.freedesktop.login1.suspend-multiple-sessions") && subject.user == "$user")
    {
    return polkit.Result.YES;
    }
});
EOF
	;;
esac

#read -n 1 -s -r -p "Press any key to continue"
#sed -i "/debugging/ s/false/true/" /usr/share/kodi/addons/skin.estuary/addon.xml

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
chown $user:$group /home/$user/.kodi/userdata/advancedsettings.xml

send_delay=350
echo "pause for 30 seconds for kodi to startup"
sleep 30

kodi-send -a "InhibitScreensaver(true)"
#exit

#enable version check (bookworm), enable spectrum (trixie)
kodi-send -a "SetFocus(11)" -d $send_delay
kodi-send -a "Action(Select, 10100)" -d $send_delay

kodi-send -a "SetFocus(28)" -d $send_delay
kodi-send -a "Action(Select, 10140)" -d $send_delay

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
kodi-send -a "ActivateWindow(10000)" -d $send_delay

case $codename in
bookworm)
	apt-get install -y kodi21-vfs-rar kodi21-vfs-libarchive kodi21-pvr-iptvsimple kodi21-inputstream-adaptive kodi21-inputstream-ffmpegdirect kodi21-visualization-spectrum
	;;
trixie)
	wget https://www.deb-multimedia.org/pool/main/d/deb-multimedia-keyring/deb-multimedia-keyring_2024.9.1_all.deb
	dpkg -i deb-multimedia-keyring_2024.9.1_all.deb
	rm -f deb-multimedia-keyring_2024.9.1_all.deb

cat > /etc/apt/sources.list.d/dmo.sources << EOF
Types: deb
URIs: https://www.deb-multimedia.org
Suites: trixie
Architectures: $architecture
Components: main non-free
Signed-By: /usr/share/keyrings/deb-multimedia-keyring.pgp
Enabled: yes
EOF

cat > /etc/apt/preferences.d/99dmo-repository << EOF
# Lower preference from dmo-repository
Package: *
Pin: origin www.deb-multimedia.org
Pin-Priority: 100
EOF

	apt-get update
	apt-get install -y kodi-vfs-rar kodi-vfs-libarchive kodi-pvr-iptvsimple kodi-inputstream-adaptive kodi-inputstream-ffmpegdirect
	;;
esac

#kodi-send -a "RestartApp"
systemctl restart kodi.service
echo "pause for 30 seconds for kodi to restart"
sleep 30

window_id=-1

#https://forum.kodi.tv/showthread.php?tid=175418
echo "enter loop"
while [[ $window_id != 10000 ]]
do
  window_id=$(curl -s http://localhost/jsonrpc -H 'Content-Type: application/json' -d '{"jsonrpc":"2.0","method":"GUI.GetProperties","params":{"properties":["currentwindow"]},"id":1}')
  window_id=$(echo $window_id | cut -d: -f6 | cut -d, -f1)
  echo $window_id

  case $window_id in
  10100)
		sleep 0.5
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
		sleep 0.5
        kodi-send -a "SetFocus(7)" -d $send_delay
        kodi-send -a "Action(Select)" -d $send_delay
		sleep 0.5
        ;;
  esac
done
echo "end loop"

case $codename in
bookworm)
	#install spectrum with the reboot of kodi, line ~141, kodi21-visualization-spectrum
	#kodi-send -a "InstallAddon(visualization.spectrum)" -d $send_delay
	#kodi-send -a "SetFocus(11)" -d $send_delay
	#kodi-send -a "Action(Select)" -d $send_delay
	;;
trixie)
	#install versionceck
	kodi-send -a "InstallAddon(service.xbmc.versioncheck)" -d $send_delay
	kodi-send -a "SetFocus(11)" -d $send_delay
	kodi-send -a "Action(Select)" -d $send_delay
	;;
esac

#sed -i "/debugging/ s/true/false/" /usr/share/kodi/addons/skin.estuary/addon.xml

systemctl restart kodi.service
echo "pause for 30 seconds for kodi to restart"
sleep 30

#deactivate screensaver for the session
kodi-send -a "InhibitScreensaver(true)"

#view expert
kodi-send -a "ActivateWindow(10032)" -d $send_delay
kodi-send -a "settingslevelchange" -d $send_delay
kodi-send -a "settingslevelchange" -d $send_delay

#enable addons from unknown sources
kodi-send -a "ActivateWindow(10016)" -d $send_delay
kodi-send -a "SetFocus(-195)" -d $send_delay
kodi-send -a "SetFocus(-174)" -d $send_delay
kodi-send -a "Action(Select)" -d $send_delay
kodi-send -a "SetFocus(11)" -d $send_delay
kodi-send -a "Action(Select)" -d $send_delay

export NEWT_COLORS='
checkbox=black,lightgray
'

menu_options=("arch" "Arch" OFF
              "awxi" "AWXi" OFF
              "chorus" "Chorus" OFF
              "chorus2" "Chorus2" ON
              "hax" "Hax" OFF
              "partymode" "PartyMode" OFF
              "tex" "Tex" OFF)

WEBGUI=$(whiptail --notags --title "WebInterfaces" --cancel-button "No Webinterface" --radiolist \
"What WebInterface do you want?" 15 60 8 \
"${menu_options[@]}" 3>&1 1>&2 2>&3)

output=$?

case $output in
0)
	#WEBGUI=chorus
	
	case $WEBGUI in
	arch|awxi|chorus|hax|partymode|tex)
		#install chorus webinterface
		kodi-send -a "InstallAddon(webinterface."$WEBGUI")" -d $send_delay
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
		kodi-send -a "ActivateWindow(10000)" -d $send_delay
		;;
	chorus2)
		#allow remote control needed for chorus2
		kodi-send -a "ActivateWindow(10018)" -d $send_delay
		kodi-send -a "SetFocus(-199)" -d $send_delay
		kodi-send -a "SetFocus(-169)" -d $send_delay
		kodi-send -a "Action(Select)" -d $send_delay
		kodi-send -a "SetFocus(11)" -d $send_delay
		kodi-send -a "Action(Select)" -d $send_delay
		kodi-send -a "SetFocus(11)" -d $send_delay
		kodi-send -a "Action(Select)" -d $send_delay

		kodi-send -a "ActivateWindow(10000)" -d 1000

		#install chorus2 webinterface
		mkdir -p $home_path/temp/kodi_package/webinterface.default.chorus2
		cd $home_path/temp/
		wget -q -nv https://github.com/xbmc/chorus2/archive/refs/heads/master.zip
		unzip  -qq master.zip
		cp -r chorus2-master/dist/* kodi_package/webinterface.default.chorus2/
		cd $home_path/temp/kodi_package/
		zip -qqr ../webinterface.default.chorus2-custom.zip webinterface.default.chorus2
		cd $home_path/temp/
		mv webinterface.default.chorus2-custom.zip $home_path/
		cd $home_path/
		chown $user:$group webinterface.default.chorus2-custom.zip
		rm -rf $home_path/temp/

		#install zip chorus2 is immediately active
		kodi-send -a "InstallFromZip" -d $send_delay
		kodi-send -a "Action(Down)" -d $send_delay
		kodi-send -a "Action(Select)" -d $send_delay
		kodi-send -a "Action(Down)" -d $send_delay
		kodi-send -a "Action(Select)" -d $send_delay

		kodi-send -a "ActivateWindow(10000)" -d 1000
		;;
	*|none)
		;;
	esac
	;;
1)
	;;
esac

TERM=ansi whiptail --title "Installation done" --infobox "Script finished, installation done" 7 60