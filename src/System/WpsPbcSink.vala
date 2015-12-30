using WordClock;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.WpsPbcSink : GLib.Object, Jsonable, SignalSink {
	const string WPA_WPS_PBC = "wpa_cli wps_pbc";
	const string WPA_STATUS = "wpa_cli status";
	const string NTP_RESTART = "systemctl restart ntp";
	
	public static int wps_lock;
	
	public void action () {
		try{
			new Thread<int>.try("WPS PBC", () => {
				lock(wps_lock) {
					Main.message.info("WPS",-1);
					try{
						Process.spawn_command_line_sync(WPA_WPS_PBC);
						
						string output="";
						do {
							Buzzer.beep(100,2000,25);
							Process.spawn_command_line_sync(WPA_STATUS, out output);
							stdout.printf("WPS: %s\n", output);
							Thread.usleep(1000000);
						} while(output.contains("wpa_state=DISCONNECTED") || output.contains("wpa_state=SCANNING") || output.contains("wpa_state=ASSOCIATING") || output.contains("wpa_state=ASSOCIATED"));
						
						Main.message.stop();
						
						if(output.contains("wpa_state=COMPLETED")) {
							Main.message.info("Completed!");
							
							Buzzer.beep(100,3000,25);
							Buzzer.beep(400,4000,25);
						}else{
							Main.message.error("Error!");
							
							Buzzer.beep(200,1000,25);
							Thread.usleep(200000);
							Buzzer.beep(200,1000,25);
						}
						
						Process.spawn_command_line_sync(NTP_RESTART);
					}catch(Error e) {
						stderr.printf("%s\n",e.message);
					}
				}
				return 0;
			});
		}catch(Error e) {
			stderr.printf("%s\n",e.message);
		}
	}
}
