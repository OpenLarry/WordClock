using WordClock;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.DateTimeModifierSink : GLib.Object, Jsonable, SignalSink {
	public int8 years { get; set; default = 0; }
	public int8 months { get; set; default = 0; }
	public int8 days { get; set; default = 0; }
	public int8 hours { get; set; default = 0; }
	public int8 minutes { get; set; default = 0; }
	public int8 seconds { get; set; default = 0; }
	
	public void action () {
		try{
			// do not modifiy time if set via ntp
			int exit_status;
			Process.spawn_sync("/usr/bin", {"chronyc","waitsync","1"}, null, SpawnFlags.LEAVE_DESCRIPTORS_OPEN, null, null, null, out exit_status);
			if(exit_status == 0) return;
			
			string date = new DateTime.now_utc().add_full(this.years,this.months,this.days,this.hours,this.minutes,this.seconds).format("%Y-%m-%d %H:%M:%S");
			
			Process.spawn_sync("/bin", {"date","-u","-s",date}, null, SpawnFlags.LEAVE_DESCRIPTORS_OPEN, null);
		}catch(Error e) {
			warning(e.message);
		}
	}
}
