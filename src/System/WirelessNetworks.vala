using WordClock;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.WirelessNetworks : GLib.Object {
	const string INTERFACE = "wlan0";
	
	public JsonableTreeMap<WirelessNetwork> get_networks() throws SpawnError {
		var map = new JsonableTreeMap<WirelessNetwork>();
		string output = "";
		Process.spawn_sync("/usr/sbin", {"wpa_cli", "-i"+INTERFACE, "list_networks"}, null, SpawnFlags.LEAVE_DESCRIPTORS_OPEN, null, out output);
		
		try {
			Regex regex = /^(\d+)\t([^\t]+)\t([^\t]+)\t([^\t]*?)$/m;
			MatchInfo match_info;
			if( regex.match( output, 0, out match_info ) ) {
				do {
					map[match_info.fetch(1)] = new WirelessNetwork(
						match_info.fetch(2).replace("\\\\","\\").replace("\\\"","\""),
						"*",
						!match_info.fetch(4).contains("DISABLED"),
						match_info.fetch(4).contains("CURRENT")
					);
				}
				while ( match_info.next() );
			}
		} catch ( RegexError e ) {
			warning(e.message);
		}
		
		return map;
	}
	
	public uint add_network(WirelessNetwork network) throws SpawnError, WirelessNetworkError {
		string output = "";
		
		Process.spawn_sync("/usr/sbin", {"wpa_cli", "-i"+INTERFACE, "add_network"}, null, SpawnFlags.LEAVE_DESCRIPTORS_OPEN, null, out output);
		
		uint id = 0;
		if(output.scanf("%u", out id) == 1) {
			try{
				this.edit_network(id, network);
			} catch ( SpawnError e ) {
				this.remove_network(id);
				throw e;
			} catch ( WirelessNetworkError e ) {
				this.remove_network(id);
				throw e;
			}
			return id;
		}else{
			throw new WirelessNetworkError.COMMAND_FAILED("wpa_cli add_network failed!");
		}
	}
	
	public void edit_network(uint id, WirelessNetwork network) throws SpawnError, WirelessNetworkError {
		string output = "";
		Process.spawn_sync("/usr/sbin", {"wpa_cli", "-i"+INTERFACE, "set_network", id.to_string(), "ssid", "\""+network.ssid+"\""}, null, SpawnFlags.LEAVE_DESCRIPTORS_OPEN, null, out output);
		if(output != "OK\n") throw new WirelessNetworkError.COMMAND_FAILED("wpa_cli set_network ssid failed!");;
		
		if(network.psk != "*") {
			Process.spawn_sync("/usr/sbin", {"wpa_cli", "-i"+INTERFACE, "set_network", id.to_string(), "psk", "\""+network.psk+"\""}, null, SpawnFlags.LEAVE_DESCRIPTORS_OPEN, null, out output);
			if(output != "OK\n") throw new WirelessNetworkError.COMMAND_FAILED("wpa_cli set_network psk failed! (Key too short?)");
		}
		
		Process.spawn_sync("/usr/sbin", {"wpa_cli", "-i"+INTERFACE, network.enabled ? "enable_network" : "disable_network", id.to_string()}, null, SpawnFlags.LEAVE_DESCRIPTORS_OPEN, null, out output);
		if(output != "OK\n") throw new WirelessNetworkError.COMMAND_FAILED("wpa_cli enable_network/disable_network failed!");
		
		this.save_config();
	}
	
	public void remove_network(uint id) throws SpawnError, WirelessNetworkError {
		string output = "";
		Process.spawn_sync("/usr/sbin", {"wpa_cli", "-i"+INTERFACE, "remove_network", id.to_string()}, null, SpawnFlags.LEAVE_DESCRIPTORS_OPEN, null, out output);
		
		if(output != "OK\n") throw new WirelessNetworkError.COMMAND_FAILED("wpa_cli remove_network failed!");
		
		this.save_config();
	}
	
	private void save_config() throws SpawnError, WirelessNetworkError {
		string output = "";
		Process.spawn_sync("/usr/sbin", {"wpa_cli", "-i"+INTERFACE, "save_config"}, null, SpawnFlags.LEAVE_DESCRIPTORS_OPEN, null, out output);
		
		if(output != "OK\n") throw new WirelessNetworkError.COMMAND_FAILED("wpa_cli save_config failed!");
	}
}

// container class
public class WordClock.WirelessNetwork : GLib.Object, Jsonable {
	public string ssid { get; set; default = ""; }
	public string psk { get; set; default = "*"; }
	public bool enabled { get; set; default = false; }
	public bool current { get; set; default = false; }
	
	public WirelessNetwork(string ssid = "", string psk = "*", bool enabled = false, bool current = false) {
		this.ssid = ssid;
		this.psk = psk;
		this.enabled = enabled;
		this.current = current;
	}
}

public errordomain WordClock.WirelessNetworkError {
	COMMAND_FAILED
}
