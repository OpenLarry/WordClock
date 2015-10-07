using WordClock;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public abstract class WordClock.ClockWiringRenderer : GLib.Object, FrameRenderer {
	private ClockWiring wiring;
	
	public ClockWiringRenderer( ClockWiring wiring ) {
		this.wiring = wiring;
	}
	
	public void render( Color[,] leds ) {
		this.render_clock( wiring.getMatrix( leds ), wiring.getMinutes( leds ), wiring.getSeconds( leds ) );
	}
	
	public abstract void render_clock( Color[,] leds_matrix, Color[] leds_minutes, Color[] leds_seconds );
}
