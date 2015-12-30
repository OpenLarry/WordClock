using WordClock;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.InfoSink : GLib.Object, Jsonable, SignalSink {
	const string IFCONFIG = "ifconfig wlan0";
	const string IWCONFIG = "iwconfig wlan0";
	const string HOSTNAME = "hostname";
	
	public void action () {
		string output, ip = "none", wlan = "none", hostname = "none";
		try{
			Process.spawn_command_line_sync(IFCONFIG, out output);
			
			Regex regex = /inet Adresse:((\d{1,3}\.){3}\d{1,3})/;
			MatchInfo match_info;
			if( regex.match( output, 0, out match_info ) ) {
				ip = match_info.fetch(1);
			}
		}catch(Error e) {
			stderr.printf("%s\n",e.message);
		}
		
		try{
			Process.spawn_command_line_sync(IWCONFIG, out output);
			
			Regex regex = /ESSID:"(.*?)"/;
			MatchInfo match_info;
			if( regex.match( output, 0, out match_info ) ) {
				wlan = match_info.fetch(1);
			}
		}catch(Error e) {
			stderr.printf("%s\n",e.message);
		}
		
		try{
			Process.spawn_command_line_sync(HOSTNAME, out output);
			
			hostname = output;
		}catch(Error e) {
			stderr.printf("%s\n",e.message);
		}
		
		Main.message.info(@"IP: $ip  HOST: $hostname  WLAN: $wlan");
	}
}
