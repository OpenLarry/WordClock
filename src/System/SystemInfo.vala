using WordClock;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.SystemInfo : GLib.Object, Jsonable {
	const string INTERFACE = "wlan0";
	const string MAC_ADDRESS = "/sys/class/net/"+INTERFACE+"/address";
	const string FILESYSTEM_VERSION = "/mnt/root-ro/build";
	
	// get ip address
	public string ip {
		owned get {
			Linux.Network.IfAddrs addrs;
			if(Linux.Network.getifaddrs(out addrs) == 0) {
				unowned Linux.Network.IfAddrs? next;
				char[] host = new char[32];
				for(next = addrs; next != null; next = next.ifa_next) {
					if(next.ifa_addr == null) continue;
					if(next.ifa_addr.sa_family != Posix.AF_INET) continue;
					if(next.ifa_name != INTERFACE) continue;
					
					Posix.socklen_t socklen = (next.ifa_addr.sa_family == Posix.AF_INET) ? (Posix.socklen_t) sizeof(Posix.SockAddrIn) : (Posix.socklen_t) sizeof(Posix.SockAddrIn6);
					char[] service = {};
					if(Posix.getnameinfo(next.ifa_addr, socklen, host, service, Posix.NI_NUMERICHOST) != 0) continue;
					
					return (string) host;
				}
			}
			return "none";
		}
	}
	
	// get wlan ESSID
	public string wlan {
		owned get {
			try{
				string output;
				Process.spawn_sync("/sbin", {"iwconfig", INTERFACE}, null, SpawnFlags.LEAVE_DESCRIPTORS_OPEN, null, out output);
				
				Regex regex = /ESSID:"(.*?)"/;
				MatchInfo match_info;
				if( regex.match( output, 0, out match_info ) ) {
					return match_info.fetch(1);
				}
			}catch(Error e) {
				stderr.printf("%s\n",e.message);
			}
			return "none";
		}
	}
	
	// get hostname
	public string hostname {
		owned get {
			char[] str = "                ".to_utf8();
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
				var file = GLib.File.new_for_path(MAC_ADDRESS);
				var dis = new GLib.DataInputStream( file.read() );
				
				return dis.read_line().chomp();
			} catch( Error e ) {
				stderr.printf("Error: %s\n", e.message);
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
				stderr.printf("Error: %s\n", e.message);
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
