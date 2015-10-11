using WordClock;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public abstract class WordClock.ClockRenderer : GLib.Object, FrameRenderer {
	private ClockWiring wiring;
	
	public ClockRenderer( ClockWiring wiring ) {
		this.wiring = wiring;
	}
	
	public bool render( Color[,] leds ) {
		return this.render_clock( wiring.getMatrix( leds ), wiring.getMinutes( leds ), wiring.getSeconds( leds ) );
	}
	
	public abstract bool render_clock( Color[,] leds_matrix, Color[] leds_minutes, Color[] leds_seconds );
}
