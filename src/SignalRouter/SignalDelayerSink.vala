using WordClock;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.SignalDelayerSink : GLib.Object, Jsonable, SignalSink {
	public uint delay { get; set; default = 60; }
	public SignalSink sink { get; set; default = null; }
	
	private uint timeout = 0;
	
	public void action () {
		lock(this.timeout) {
			if(this.timeout > 0) GLib.Source.remove(this.timeout);
			this.timeout = GLib.Timeout.add_seconds(this.delay, () => {
				// ignore timeout if no other reference is held anymore
				if(this.ref_count == 1) return GLib.Source.REMOVE;
				
				lock(this.timeout) {
					if(this.sink != null) this.sink.action();
					this.timeout = 0;
				}
				
				return GLib.Source.REMOVE;
			});
		}
	}
}
