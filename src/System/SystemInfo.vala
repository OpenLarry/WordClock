using WordClock;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.SystemInfo : GLib.Object, Jsonable {
	const string FILESYSTEM_VERSION = "/mnt/root-ro/build";
	
	// get ip address
	public string ip {
		owned get {
			try {
				return Main.settings.get<WirelessNetworks>().get_status()["ip_address"] ?? "none";
			} catch( Error e ) {
				warning(e.message);
				return "none";
			}
		}
	}
	
	// get wlan ESSID
	public string wlan {
		owned get {
			try{
				return Main.settings.get<WirelessNetworks>().get_status()["ssid"] ?? "none";
			}catch(Error e) {
				warning(e.message);
				return "none";
			}
		}
	}
	
	// get hostname
	public string hostname {
		owned get {
			char[] str = new char[16];
			if(Posix.gethostname(str) == 0) {
				return (string) str;
			}	
			return "none";
		}
	}
	
	// get kernel version
	public string kernel {
		owned get {
			Posix.utsname utsname = Posix.utsname();
			return @"$(utsname.sysname) $(utsname.release)";
		}
	}
	
	// get full kernel version
	public string kernel_full {
		owned get {
			Posix.utsname utsname = Posix.utsname();
			return @"$(utsname.sysname) $(utsname.release) $(utsname.version) $(utsname.machine)";
		}
	}
	
	// get mac address
	public string mac {
		owned get {
			try {
				return Main.settings.get<WirelessNetworks>().get_status()["address"] ?? "none";
			} catch( Error e ) {
				warning(e.message);
				return "none";
			}
		}
	}
	
	// get filesystem version
	public string filesystem {
		owned get {
			try {
				var file = GLib.File.new_for_path(FILESYSTEM_VERSION);
				var dis = new GLib.DataInputStream( file.read() );
				
				return dis.read_line().chomp();
			} catch( Error e ) {
				warning(e.message);
				return "none";
			}
		}
	}
	
	// get WordClock version
	public string version {
		owned get {
			return Version.GIT_DESCRIBE;
		}
	}
}
