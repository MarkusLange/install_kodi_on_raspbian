# install kodi on raspbian trixie
install kodi on raspbian trixie

this little script installs kodi on raspbian trixie (lite) I put some expense in it so there are some points it does
* install kodi on the active user
* creats a service for it (systemd)
* it let you run the webinterface with previleged rights so the webinterface is on port 80
* it adds the https://www.deb-multimedia.org repository to add the rar-archieve package and put the priority down to not interfere raspbian
* it installs archive and rar-archive support
* it installs iptvsimple
* add polkit rules to the user who runs kodi so you can shut it down from the interface
* creates advancedsettings to show the temperatue of the pi correcty
* installs chorus as webinterface
* preconfigure the addons with kodi-send and json

System should be up to date

Just get it with:

`wget https://raw.githubusercontent.com/MarkusLange/install_kodi_on_raspbian_trixie/refs/heads/main/install_kodi_trixie.bash`

Make it executable:

`chmod +x install_kodi_trixie.bash`

Execute it:

`sudo ./install_kodi_trixie.bash`
