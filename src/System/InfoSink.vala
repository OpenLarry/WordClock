using WordClock;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.InfoSink : GLib.Object, Jsonable, SignalSink {
	const string INTERFACE = "wlan0";
	
	public void action () {
		string output, ip = "none", wlan = "none", hostname = "none", kernel = "unknown";
		
		// get ip address
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
				
				ip = (string) host;
				break;
			}
		}
		
		/* NOTE
		 * For some reason SpawnFlags MUST NOT contain SEARCH_PATH and MUST contain LEAVE_DESCRIPTORS_OPEN
		 * If not, glib functions g_malloc() and opendir() hang randomly with buildroot and the child process does not terminate. Don't know.
		 * For this reason Process.spawn_command_line_sync can not be used!
		 */
		try{
			Process.spawn_sync("/sbin", {"iwconfig", INTERFACE}, null, SpawnFlags.LEAVE_DESCRIPTORS_OPEN, null, out output);
			
			Regex regex = /ESSID:"(.*?)"/;
			MatchInfo match_info;
			if( regex.match( output, 0, out match_info ) ) {
				wlan = match_info.fetch(1);
			}
		}catch(Error e) {
			stderr.printf("%s\n",e.message);
		}
		
		try{
			Process.spawn_sync("/bin", {"hostname"}, null, SpawnFlags.LEAVE_DESCRIPTORS_OPEN, null, out output);
			
			hostname = output;
		}catch(Error e) {
			stderr.printf("%s\n",e.message);
		}
		
		try{
			Process.spawn_sync("/bin", {"uname","-sr"}, null, SpawnFlags.LEAVE_DESCRIPTORS_OPEN, null, out output);
			
			kernel = output;
		}catch(Error e) {
			stderr.printf("%s\n",e.message);
		}
		
		(Main.settings.objects["message"] as MessageOverlay).info(@"WordClock $(Version.GIT_DESCRIBE)  IP: $ip  Host: $hostname  WLAN: $wlan  Kernel: $kernel");
	}
}
