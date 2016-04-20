using WordClock;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.DateTimeModifierSink : GLib.Object, Jsonable, SignalSink {
	const string DATE_CMD = "date +%%T -s \"%s\"";
	
	public int8 years { get; set; default = 0; }
	public int8 months { get; set; default = 0; }
	public int8 days { get; set; default = 0; }
	public int8 hours { get; set; default = 0; }
	public int8 minutes { get; set; default = 0; }
	public int8 seconds { get; set; default = 0; }
	
	public void action () {
		try{
			string date = new DateTime.now(Main.timezone).add_full(this.years,this.months,this.days,this.hours,this.minutes,this.seconds).format("%T");
			
			Process.spawn_sync("/bin", {"date","+%T","-s",date}, null, SpawnFlags.LEAVE_DESCRIPTORS_OPEN, null);
		}catch(Error e) {
			stderr.printf("%s\n",e.message);
		}
	}
}
