using WordClock;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.WpsPbcSink : GLib.Object, Jsonable, SignalSink {
	private static Cancellable cancellable = null;
	private static Thread<int> thread;
	
	private static uint message_id;
	
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
		message_id = (Main.settings.objects["message"] as MessageOverlay).info("WPS",-1);
		try{
			Process.spawn_sync("/usr/sbin", {"wpa_cli","wps_pbc"}, null, SpawnFlags.LEAVE_DESCRIPTORS_OPEN, null);
			
			string output="";
			do {
				Buzzer.beep(100,2000,25);
				Process.spawn_sync("/usr/sbin", {"wpa_cli","status"}, null, SpawnFlags.LEAVE_DESCRIPTORS_OPEN, null, out output);
				stdout.printf("WPS: %s\n", output);
				Thread.usleep(1000000);
			} while(!cancellable.is_cancelled() && (output.contains("wpa_state=DISCONNECTED") || output.contains("wpa_state=SCANNING") || output.contains("wpa_state=ASSOCIATING") || output.contains("wpa_state=ASSOCIATED") || output.contains("wpa_state=INTERFACE_DISABLED")));
			
			(Main.settings.objects["message"] as MessageOverlay).stop(message_id);
			
			if(cancellable.is_cancelled()) {
				Process.spawn_sync("/usr/sbin", {"wpa_cli","wps_cancel"}, null, SpawnFlags.LEAVE_DESCRIPTORS_OPEN, null, out output);
				
				(Main.settings.objects["message"] as MessageOverlay).info("Cancelled!");
			}else if(output.contains("wpa_state=COMPLETED")) {
				cancellable.cancel();
				(Main.settings.objects["message"] as MessageOverlay).success("Completed!");
				
				Buzzer.beep(100,3000,25);
				Buzzer.beep(400,4000,25);
			}else{
				cancellable.cancel();
				(Main.settings.objects["message"] as MessageOverlay).error("Error!");
				
				Buzzer.beep(200,1000,25);
				Thread.usleep(200000);
				Buzzer.beep(200,1000,25);
			}
		}catch(Error e) {
			stderr.printf("%s\n",e.message);
		}
		return 0;
	}
}
