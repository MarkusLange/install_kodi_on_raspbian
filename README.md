# install kodi on raspbian bookworm/trixie lite

this little script installs kodi on raspbian bookworm/trixie (lite is assumed) I put some expense in it so there are some points it does
* install kodi on the active user
* creats a service for it (systemd)
* it let you run the webinterface with previleged rights so the webinterface is on port 80
* it adds the https://www.deb-multimedia.org repository to add the rar-archieve package and put the priority down to not interfere raspbian (trixie only)
* it installs archive and rar-archive support
* it installs iptvsimple
* add polkit rules to the user who runs kodi so you can shut it down from the interface (trixie only)
* creates advancedsettings to show the temperatue of the pi correctly
* installs a webinterface of your choise (Arch, AWXi, Chorus, Chorus2, Hax, PartyMode, Tex) or none
* preconfigure the addons with kodi-send and json

Now with some whiptail gui parts
Installation Information
![Installation Information](https://github.com/MarkusLange/install_kodi_on_raspbian/blob/main/screenshots/Installation_Information.PNG?raw=true)
Ask about the WebInterface
![Ask about the WebInterface](https://github.com/MarkusLange/install_kodi_on_raspbian/blob/main/screenshots/WebInterfaces.PNG?raw=true)
Done
![Done](https://github.com/MarkusLange/install_kodi_on_raspbian/blob/main/screenshots/Installation_Done.PNG?raw=true)

System should be up to date

Just get it with:

`wget https://raw.githubusercontent.com/MarkusLange/install_kodi_on_raspbian/refs/heads/main/install_kodi_on_raspbian.bash`

Make it executable:

`chmod +x install_kodi_on_raspbian.bash`

Execute it:

`sudo ./install_kodi_on_raspbian.bash`
