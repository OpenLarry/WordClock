using WordClock;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.ImageSink : GLib.Object, Jsonable, SignalSink {
	public string path { get; set; default = ""; }
	public int x_speed { get; set; default = 0; }
	public int y_speed { get; set; default = 4; }
	public uint count { get; set; default = 1; }
	
	public void action () {
		(Main.settings.objects["image"] as ImageOverlay).display(this.path, this.x_speed, this.y_speed, (int) this.count.clamp(1,int.MAX));
	}
}
