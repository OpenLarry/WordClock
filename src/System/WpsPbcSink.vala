using WordClock;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.WpsPbcSink : GLib.Object, Jsonable, SignalSink {
	const string WPA_WPS_PBC = "wpa_cli wps_pbc";
	const string WPA_WPS_CANCEL = "wpa_cli wps_cancel";
	const string WPA_STATUS = "wpa_cli status";
	const string NTP_RESTART = "systemctl restart ntp";
	
	private static Cancellable cancellable = null;
	private static Thread<int> thread;
	
	public void action () {
		lock(cancellable) {
			if(cancellable == null || cancellable.is_cancelled()) {
				cancellable = new Cancellable();
				
				try{
					thread = new Thread<int>.try("WPS PBC", run_wps);
				}catch(Error e) {
					stderr.printf("%s\n",e.message);
				}
			}else{
				cancellable.cancel();
				
				thread.join();
			}
		}
	}
	
	private static int run_wps() {
		Main.message.info("WPS",-1);
		try{
			Process.spawn_command_line_sync(WPA_WPS_PBC);
			
			string output="";
			do {
				Buzzer.beep(100,2000,25);
				Process.spawn_command_line_sync(WPA_STATUS, out output);
				stdout.printf("WPS: %s\n", output);
				Thread.usleep(1000000);
			} while(!cancellable.is_cancelled() && (output.contains("wpa_state=DISCONNECTED") || output.contains("wpa_state=SCANNING") || output.contains("wpa_state=ASSOCIATING") || output.contains("wpa_state=ASSOCIATED") || output.contains("wpa_state=INTERFACE_DISABLED")));
			
			Main.message.stop();
			
			if(cancellable.is_cancelled()) {
				Process.spawn_command_line_sync(WPA_WPS_CANCEL);
				
				Main.message.info("Cancelled!");
			}else if(output.contains("wpa_state=COMPLETED")) {
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
		return 0;
	}
}
