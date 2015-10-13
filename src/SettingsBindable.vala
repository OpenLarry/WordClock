using WordClock;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public interface WordClock.SettingsBindable : GLib.Object {
	public abstract void bind_settings(GLib.SettingsSchemaSource sss, string name);
	public abstract void unbind_settings();
}
