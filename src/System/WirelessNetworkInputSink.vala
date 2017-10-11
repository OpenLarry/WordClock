using WordClock;
using Gee;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.WirelessNetworkInputSink : GLib.Object, Jsonable, SignalSink {
	private WirelessNetworks wireless = new WirelessNetworks();
	private static bool running = false;
	
	public void action() {
		this.async_action.begin();
	}
	
	public async void async_action() {
		if(running) return;
		running = true;
		
		debug("Trigger WirelessNetworkInputSink");
		
		SignalRouter signalrouter = (Main.settings.objects["signalrouter"] as SignalRouter);
		
		
		try {
			(Main.settings.objects["message"] as MessageOverlay).message.begin("Scanning...", MessageType.INFO, -1);
			
			// scan networks
			string[] networks_array = {};
			ArrayList<WirelessNetwork> scan_networks = wireless.scan_networks(3);
			foreach(WirelessNetwork network in scan_networks) {
				networks_array += network.ssid;
			}
			
			// choose network
			StringChooser stringchooser = new StringChooser(networks_array, "Choose network:");
			uint signalfunc = signalrouter.add_signal_func(/^remote,[RGB]\d?$/, (id,sig) => {
				switch(sig) {
					case "remote,G1": stringchooser.action(StringChooserAction.UP); break;
					case "remote,G3": stringchooser.action(StringChooserAction.DOWN); break;
					case "remote,G2": stringchooser.action(StringChooserAction.SELECT); break;
					case "remote,R2": stringchooser.action(StringChooserAction.ABORT); break;
				}
				return false; 
			}, true);
			
			int id = yield stringchooser.choose();
			signalrouter.remove_signal_func(signalfunc);
			if(id < 0) return;
			string ssid = networks_array[id];
			
			// enter password
			StringInput stringinput = new StringInput("Enter password:");
			signalfunc = signalrouter.add_signal_func(/^remote,[RGB]\d?$/, (id,sig) => {
				switch(sig) {
					case "remote,G1": stringinput.action(StringInputAction.UP); break;
					case "remote,G3": stringinput.action(StringInputAction.DOWN); break;
					case "remote,G2": stringinput.action(StringInputAction.SELECT); break;
					case "remote,R2": stringinput.action(StringInputAction.PREV); break;
					case "remote,B2": stringinput.action(StringInputAction.NEXT); break;
					case "remote,R1": stringinput.action(StringInputAction.UPPERCASE); break;
					case "remote,R3": stringinput.action(StringInputAction.LOWERCASE); break;
					case "remote,B1": stringinput.action(StringInputAction.NUMBERS); break;
					case "remote,B3": stringinput.action(StringInputAction.SPECIAL); break;
				}
				return false; 
			}, true);
			
			string? psk = yield stringinput.read();
			signalrouter.remove_signal_func(signalfunc);
			if(psk == null) return;
			
			// save network
			uint? network_id = null;
			TreeMap<string,WirelessNetwork> get_networks = wireless.get_networks();
			foreach(Map.Entry<string,WirelessNetwork> e in get_networks.entries) {
				if(e.value.ssid == ssid) {
					network_id = (uint) uint64.parse(e.key);
					break;
				}
			}
			if(network_id == null) {
				wireless.add_network(new WirelessNetwork(ssid,psk,true));
				yield (Main.settings.objects["message"] as MessageOverlay).message("OK", MessageType.SUCCESS, 1);
			}else{
				wireless.edit_network(network_id, new WirelessNetwork(ssid,psk,true));
				yield (Main.settings.objects["message"] as MessageOverlay).message("OK", MessageType.SUCCESS, 1);
			}
		} catch( WirelessNetworkError e ) {
			if(e is WirelessNetworkError.SET_NETWORK_PSK_FAILED) {
				yield (Main.settings.objects["message"] as MessageOverlay).message("Error! Password too short?", MessageType.ERROR, 1);
			}else{
				yield (Main.settings.objects["message"] as MessageOverlay).message(e.message, MessageType.ERROR, 1);
			}
		} catch( Error e ) {
			yield (Main.settings.objects["message"] as MessageOverlay).message(e.message, MessageType.ERROR, 1);
		} finally {
			running = false;
			debug("Finished WirelessNetworkInputSink");
		}
	}
}