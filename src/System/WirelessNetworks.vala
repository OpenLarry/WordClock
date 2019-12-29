using WordClock;
using Gee;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.WirelessNetworks : GLib.Object, Jsonable {
	public bool connection_overlays { get; set; default = false; }
	private bool connection_overlays_override = false;
	
	private WPACtrl wpa_ctrl = new WPACtrl();
	
	private bool wps_running = false;
	private Cancellable? imageoverlay_cancellable = null;
	
	public WirelessNetworks() throws WirelessNetworkError, WPACtrlError, IOChannelError {
		this.wpa_ctrl.event.connect( this.event );
	}
	
	private void event( string event ) {
		if((this.connection_overlays || this.connection_overlays_override) && (event.contains(WPAClient.WPA_EVENT_CONNECTED) || event.contains(WPAClient.WPA_EVENT_DISCONNECTED))) {
			this.connection_overlay.begin(event.contains(WPAClient.WPA_EVENT_CONNECTED));
		}
	}
	
	private async void connection_overlay(bool connected) {
		if(imageoverlay_cancellable != null) imageoverlay_cancellable.cancel();
		
		if((Main.settings.objects["clockrenderer"] as ClockRenderer).overwrite_active()) return;
		
		imageoverlay_cancellable = new Cancellable();
		if(connected) {
			ClockRenderer.ReturnReason ret = yield (Main.settings.objects["image"] as ImageOverlay).image("/usr/share/wordclock/wlan_connected.png", 0, 4, 3, imageoverlay_cancellable);
		
			string ssid = "none";
			try {
				ssid = (Main.settings.objects["wirelessnetworks"] as WirelessNetworks).get_status()["ssid"] ?? "none";
			} catch ( Error e ) {
				warning(e.message);
			}
				
			if(ret == ClockRenderer.ReturnReason.TERMINATED) {
				yield (Main.settings.objects["message"] as MessageOverlay).message(ssid, MessageType.INFO, 1, imageoverlay_cancellable);
			}
		} else {
			yield (Main.settings.objects["image"] as ImageOverlay).image("/usr/share/wordclock/wlan_disconnected.png", 0, 2, 3, imageoverlay_cancellable);
		}
	}
	
	public async void connection_overlay_override( uint time ) {
		this.connection_overlays_override = true;
		yield async_sleep(time);
		this.connection_overlays_override = false;
	}
	
	public JsonableTreeMap<WirelessNetwork> get_networks() throws WirelessNetworkError, WPACtrlError {
		var map = new JsonableTreeMap<WirelessNetwork>();
		string output = this.wpa_ctrl.request("LIST_NETWORKS");
		
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
	
	public uint add_network(WirelessNetwork network) throws WirelessNetworkError, WPACtrlError {
		string output = this.wpa_ctrl.request("ADD_NETWORK");
		
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
	
	public void edit_network(uint id, WirelessNetwork network) throws WirelessNetworkError, WPACtrlError {
		string output = this.wpa_ctrl.request("SET_NETWORK "+id.to_string()+" ssid \""+network.ssid+"\"");
		if(output != "OK\n") throw new WirelessNetworkError.SET_NETWORK_SSID_FAILED("Set network ssid failed!");;
		
		if(network.psk != "*") {
			output = this.wpa_ctrl.request("SET_NETWORK "+id.to_string()+" psk \""+network.psk+"\"");
			if(output != "OK\n") throw new WirelessNetworkError.SET_NETWORK_PSK_FAILED("Set network psk failed! (Key too short?)");
		}
		
		output = this.wpa_ctrl.request((network.enabled ? "ENABLE_NETWORK " : "DISABLE_NETWORK ")+id.to_string());
		if(output != "OK\n") throw new WirelessNetworkError.ENABLEDISABLE_NETWORK_FAILED("Enable/disable network failed!");
		
		this.save_config();
	}
	
	public void remove_network(uint id) throws WirelessNetworkError, WPACtrlError {
		string output = this.wpa_ctrl.request("REMOVE_NETWORK "+id.to_string());
		if(output != "OK\n") throw new WirelessNetworkError.REMOVE_NETWORK_FAILED("Remove network failed!");
		
		this.save_config();
	}
	
	public async JsonableArrayList<WirelessNetwork> scan_networks(uint8 scan_count = 1, uint8 scan_interval = 5) throws WirelessNetworkError, WPACtrlError, RegexError {
		TreeSet<WirelessNetwork> networks = new TreeSet<WirelessNetwork>( (a,b) => {
			int r = a.mac.ascii_casecmp(b.mac);
			if(r!=0) return r;
			return a.ssid.ascii_casecmp(b.ssid);
		} );
		
		for(uint8 i=0; i<scan_count; i++) {
			if(this.wps_running) throw new WirelessNetworkError.WPS_RUNNING("WPS running!");
			
			string output = this.wpa_ctrl.request("SCAN");
			// ignore FAIL-BUSY and wait for results of pending scan
			if(output != "OK\n" && output != "FAIL-BUSY\n") throw new WirelessNetworkError.SCAN_FAILED("Scan failed!");
			
			// wait for scan results
			ulong signal_id = this.wpa_ctrl.event.connect( (event) => {
				if(event.contains(WPAClient.WPA_EVENT_SCAN_RESULTS)) this.scan_networks.callback();
			} );
			yield;
			this.wpa_ctrl.disconnect(signal_id);
			
			output = this.wpa_ctrl.request("SCAN_RESULTS");
			
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
	
	private void save_config() throws WirelessNetworkError, WPACtrlError {
		string output = this.wpa_ctrl.request("SAVE_CONFIG");
		if(output != "OK\n") throw new WirelessNetworkError.SAVE_CONFIG_FAILED("Save config failed!");
	}
	
	public void reassociate() throws WirelessNetworkError, WPACtrlError {
		this.connection_overlay_override.begin(10000);
		
		string output = this.wpa_ctrl.request("REASSOCIATE");
		if(output != "OK\n") throw new WirelessNetworkError.REASSOCIATE_FAILED("Reassociate failed!");
	}
	
	public TreeMap<string,string> get_status() throws WirelessNetworkError, WPACtrlError, RegexError {
		string output = this.wpa_ctrl.request("STATUS");
		
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
	public async bool? wps_pbc( Cancellable? cancel_task, Cancellable cancel ) throws WirelessNetworkError, WPACtrlError {
		if(this.wps_running) return false;
		this.wps_running = true;
		
		try {
			string output = this.wpa_ctrl.request("WPS_PBC");
			if(output != "OK\n") throw new WirelessNetworkError.WPS_PBC_FAILED("WPS PBC failed!");
			
			bool? success = null;
			ulong signal_id = this.wpa_ctrl.event.connect((event) => {
				if(event.contains(WPAClient.WPS_EVENT_SUCCESS)) {
					success = true;
					this.connection_overlay_override.begin(10000);
					this.wps_pbc.callback();
				} else if(event.contains(WPAClient.WPS_EVENT_FAIL)) {
					success = false;
					this.wps_pbc.callback();
				} else if(event.contains(WPAClient.WPS_EVENT_TIMEOUT)) {
					this.wps_pbc.callback();
				}
			});
			ulong cancel_id = cancel.connect(() => {
				this.wps_pbc.callback();
			});
			yield;
			this.wpa_ctrl.disconnect(signal_id);
			if(!cancel.is_cancelled()) cancel.disconnect(cancel_id);
			
			if(cancel.is_cancelled()) {
				output = this.wpa_ctrl.request("WPS_CANCEL");
				if(output != "OK\n") throw new WirelessNetworkError.WPS_CANCEL_FAILED("WPS CANCEL failed!");
				
				// otherwise wpa_supplicant stops scanning after wps sometimes
				output = this.wpa_ctrl.request("SCAN");
				// ignore output
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
	REASSOCIATE_FAILED,
	SCAN_FAILED,
	WPS_PBC_FAILED,
	WPS_CANCEL_FAILED,
	WPS_RUNNING
}
