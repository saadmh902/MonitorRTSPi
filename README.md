<h1>MonitorRTSPi</h1>
<b>A simple set of scripts that turns your Raspberry Pi into a plug and play device to view an security feed on a local network</b>
<p>Useful to watch a front door camera for example</p>
<p>Currently ONLY supports 1 stream</p>

<h2>Features:</h2>
<p>Simple set up, enter IP, username and password and desired channel of the stream</p>
<p>Uses VLC to open RTSP stream</p>
<p>Detects if stream goes down and will automatically reinitialize stream</p>
<p>If the Raspberry Pi loses power it will automatically relaunch stream on boot up</p>


<h2>Installation Instructions</h2>
<p>Download MonitorRTSPi-Installer.sh to /home/user/ directory, then run the file</p>
<code>curl -o /home/<user>/MonitorRTSPi-Installer.sh https://raw.githubusercontent.com/saadmh902/MonitorRTSPi/main/MonitorRTSPi-Installer.sh
./MonitorRTSPI-Installer.sh</code>
