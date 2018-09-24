using WordClock;
using Gee;
using WPAClient;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.WirelessNetworks : GLib.Object {
	const string WPA_SUPPLICANT_SOCKET = "/var/run/wpa_supplicant/%s";
	const string INTERFACE = "wlan0";
	private WPACtrl wpa_ctrl_cmd;
	private WPACtrl wpa_ctrl_msg;
	private signal void wpa_ctrl_event( string event );
	
	private bool wps_running = false;
	
	private uint source;
	
	public WirelessNetworks() throws WirelessNetworkError, IOChannelError {
		// connect to wpa_supplicant
		this.wpa_ctrl_cmd = new WPACtrl( WPA_SUPPLICANT_SOCKET.printf( INTERFACE ) );
		if(this.wpa_ctrl_cmd == null) throw new WirelessNetworkError.WPA_CTRL_ERROR("WPACtrl is null");
		this.wpa_ctrl_msg = new WPACtrl( WPA_SUPPLICANT_SOCKET.printf( INTERFACE ) );
		if(this.wpa_ctrl_msg == null) throw new WirelessNetworkError.WPA_CTRL_ERROR("WPACtrl is null");
		
		// listen for unsolicited messages
		if(!this.wpa_ctrl_msg.attach()) throw new WirelessNetworkError.WPA_CTRL_ERROR("WPACtrl attach failed");
		
		// add watch
		var channel = new IOChannel.unix_new(this.wpa_ctrl_msg.get_fd());
		channel.set_encoding(null);
		
		this.source = channel.add_watch(IOCondition.IN, this.receive);
		if(this.source == 0) {
			throw new WirelessNetworkError.WPA_CTRL_ERROR("Cannot add watch on IOChannel");
		}
	}
	
	~WirelessNetworks() {
		this.wpa_ctrl_msg.detach();
		if(this.source > 0) Source.remove(this.source);
	}
	
	private bool receive( IOChannel source, IOCondition condition ) {
		string? resp = this.wpa_ctrl_msg.recv();
		if(resp == null) return Source.CONTINUE;
		
		if(!(Main.settings.objects["clockrenderer"] as ClockRenderer).overwrite_active()) {
			if(resp.contains(WPA_EVENT_CONNECTED))
				(Main.settings.objects["message"] as MessageOverlay).success("Connected!");
			else if(resp.contains(WPA_EVENT_DISCONNECTED))
				(Main.settings.objects["message"] as MessageOverlay).error("Disconnected!");
		}
		
		this.wpa_ctrl_event( resp );
		
		return Source.CONTINUE;
	}
	
	public JsonableTreeMap<WirelessNetwork> get_networks() throws WirelessNetworkError {
		var map = new JsonableTreeMap<WirelessNetwork>();
		string? output = this.wpa_ctrl_cmd.request("LIST_NETWORKS");
		if(output == null) throw new WirelessNetworkError.WPA_CTRL_ERROR("Request failed");
		
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
	
	public uint add_network(WirelessNetwork network) throws WirelessNetworkError {
		string? output = this.wpa_ctrl_cmd.request("ADD_NETWORK");
		if(output == null) throw new WirelessNetworkError.WPA_CTRL_ERROR("Request failed");
		
		uint id = 0;
		if(output.scanf("%u", out id) == 1) {
			try{
				this.edit_network(id, network);
			} catch ( WirelessNetworkError e ) {
				this.remove_network(id);
				throw e;
			}
			return id;
		}else{
			throw new WirelessNetworkError.ADD_NETWORK_FAILED("Add network failed!");
		}
	}
	
	public void edit_network(uint id, WirelessNetwork network) throws WirelessNetworkError {
		string? output = this.wpa_ctrl_cmd.request("SET_NETWORK "+id.to_string()+" ssid \""+network.ssid+"\"");
		if(output == null) throw new WirelessNetworkError.WPA_CTRL_ERROR("Request failed");
		
		if(output != "OK\n") throw new WirelessNetworkError.SET_NETWORK_SSID_FAILED("Set network ssid failed!");;
		
		if(network.psk != "*") {
			output = this.wpa_ctrl_cmd.request("SET_NETWORK "+id.to_string()+" psk \""+network.psk+"\"");
			if(output == null) throw new WirelessNetworkError.WPA_CTRL_ERROR("Request failed");
			if(output != "OK\n") throw new WirelessNetworkError.SET_NETWORK_PSK_FAILED("Set network psk failed! (Key too short?)");
		}
		
		output = this.wpa_ctrl_cmd.request((network.enabled ? "ENABLE_NETWORK " : "DISABLE_NETWORK ")+id.to_string());
		if(output == null) throw new WirelessNetworkError.WPA_CTRL_ERROR("Request failed");
		if(output != "OK\n") throw new WirelessNetworkError.ENABLEDISABLE_NETWORK_FAILED("Enable/disable network failed!");
		
		this.save_config();
	}
	
	public void remove_network(uint id) throws WirelessNetworkError {
		string? output = this.wpa_ctrl_cmd.request("REMOVE_NETWORK "+id.to_string());
		if(output == null) throw new WirelessNetworkError.WPA_CTRL_ERROR("Request failed");
		
		if(output != "OK\n") throw new WirelessNetworkError.REMOVE_NETWORK_FAILED("Remove network failed!");
		
		this.save_config();
	}
	
	public async JsonableArrayList<WirelessNetwork> scan_networks(uint8 scan_count = 1, uint8 scan_interval = 5) throws WirelessNetworkError, RegexError {
		TreeSet<WirelessNetwork> networks = new TreeSet<WirelessNetwork>( (a,b) => {
			int r = a.mac.ascii_casecmp(b.mac);
			if(r!=0) return r;
			return a.ssid.ascii_casecmp(b.ssid);
		} );
		
		for(uint8 i=0; i<scan_count; i++) {
			if(this.wps_running) throw new WirelessNetworkError.WPS_RUNNING("WPS running!");
			
			string? output = this.wpa_ctrl_cmd.request("SCAN");
			if(output == null) throw new WirelessNetworkError.WPA_CTRL_ERROR("Request failed");
			if(output != "OK\n") throw new WirelessNetworkError.SCAN_FAILED("Scan failed!");
			
			// wait for scan results
			ulong signal_id = this.wpa_ctrl_event.connect( (event) => {
				if(event.contains(WPA_EVENT_SCAN_RESULTS)) this.scan_networks.callback();
			} );
			yield;
			this.disconnect(signal_id);
			
			output = this.wpa_ctrl_cmd.request("SCAN_RESULTS");
			if(output == null) throw new WirelessNetworkError.WPA_CTRL_ERROR("Request failed");
			
			Regex regex = /^((?:[\da-f]{2}:){5}[\da-f]{2})\t\d+\t(-?\d+)\t\S+\t(.*)$/m;
			MatchInfo match;
			if( regex.match( output, 0, out match ) ) {
				do {
					networks.add(new WirelessNetwork.with_mac(match.fetch(3),match.fetch(1), (int8) int.parse(match.fetch(2))));
				} while ( match.next() );
			}
			
			if(i<scan_count-1) yield async_sleep(scan_interval*1000);
		}
		
		JsonableArrayList<WirelessNetwork> ret = new JsonableArrayList<WirelessNetwork>();
		ret.add_all(networks);
		ret.sort( (a,b) => { return b.signal_level - a.signal_level; } );
		return ret;
	}
	
	private void save_config() throws WirelessNetworkError {
		string? output = this.wpa_ctrl_cmd.request("SAVE_CONFIG");
		if(output == null) throw new WirelessNetworkError.WPA_CTRL_ERROR("Request failed");
		if(output != "OK\n") throw new WirelessNetworkError.SAVE_CONFIG_FAILED("Save config failed!");
	}
	
	public TreeMap<string,string> get_status() throws WirelessNetworkError, RegexError {
		string? output = this.wpa_ctrl_cmd.request("STATUS");
		if(output == null) throw new WirelessNetworkError.WPA_CTRL_ERROR("Request failed");
		
		TreeMap<string,string> status = new TreeMap<string,string>();
		
		Regex regex = /^(.+?)=(.+)$/m;
		MatchInfo match;
		if( regex.match( output, 0, out match ) ) {
			do {
				status[match.fetch(1)] = match.fetch(2);
			} while ( match.next() );
		}
		
		return status;
	}
	
	// First Cancellable? parameter is needed, because otherwise cancellable also cancels task and throws exception
	// see: https://valadoc.org/gio-2.0/GLib.Task.set_check_cancellable.html
	// see: https://github.com/GNOME/vala/blob/master/codegen/valagasyncmodule.vala#L279
	public async bool wps_pbc( Cancellable? cancel_task, Cancellable cancel ) throws WirelessNetworkError {
		if(this.wps_running) return false;
		this.wps_running = true;
		
		try {
			string? output = this.wpa_ctrl_cmd.request("WPS_PBC");
			if(output == null) throw new WirelessNetworkError.WPA_CTRL_ERROR("Request failed");
			if(output != "OK\n") throw new WirelessNetworkError.WPS_PBC_FAILED("WPS PBC failed!");
			
			bool success = false;
			ulong signal_id = this.wpa_ctrl_event.connect((event) => {
				if(event.contains(WPS_EVENT_SUCCESS)) {
					success = true;
					this.wps_pbc.callback();
				} else if(event.contains(WPS_EVENT_TIMEOUT) || event.contains(WPS_EVENT_FAIL)) {
					this.wps_pbc.callback();
				}
			});
			ulong cancel_id = cancel.connect(() => {
				this.wps_pbc.callback();
			});
			yield;
			this.disconnect(signal_id);
			if(!cancel.is_cancelled()) cancel.disconnect(cancel_id);
			
			if(cancel.is_cancelled()) {
				output = this.wpa_ctrl_cmd.request("WPS_CANCEL");
				if(output == null) throw new WirelessNetworkError.WPA_CTRL_ERROR("Request failed");
				if(output != "OK\n") throw new WirelessNetworkError.WPS_CANCEL_FAILED("WPS CANCEL failed!");
			}
			
			return success;
		} finally {
			this.wps_running = false;;
		}
	}
}

// container class
public class WordClock.WirelessNetwork : GLib.Object, Jsonable {
	public string ssid { get; set; default = ""; }
	public string psk { get; set; default = "*"; }
	public bool enabled { get; set; default = false; }
	public bool current { get; set; default = false; }
	public string mac { get; set; default = ""; }
	public int8 signal_level { get; set; default = int8.MIN; }
	
	public WirelessNetwork(string ssid = "", string psk = "*", bool enabled = false, bool current = false) {
		this.ssid = ssid;
		this.psk = psk;
		this.enabled = enabled;
		this.current = current;
	}
	
	public WirelessNetwork.with_mac(string ssid, string mac, int8 signal_level = int8.MIN ) {
		this.ssid = ssid;
		this.mac = mac;
		this.signal_level = signal_level;
	}
}

public errordomain WordClock.WirelessNetworkError {
	ADD_NETWORK_FAILED,
	SET_NETWORK_SSID_FAILED,
	SET_NETWORK_PSK_FAILED,
	REMOVE_NETWORK_FAILED,
	ENABLEDISABLE_NETWORK_FAILED,
	SAVE_CONFIG_FAILED,
	SCAN_FAILED,
	WPS_PBC_FAILED,
	WPS_CANCEL_FAILED,
	WPS_RUNNING,
	WPA_CTRL_ERROR
}
