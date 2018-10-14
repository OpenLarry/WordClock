using WordClock;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.WPACtrl : GLib.Object {
	const string WPA_SUPPLICANT_SOCKET = "/var/run/wpa_supplicant/%s";
	const string INTERFACE = "wlan0";
	
	private WPAClient.WPACtrl? wpa_ctrl_cmd = null;
	private WPAClient.WPACtrl? wpa_ctrl_msg = null;
	public signal void event( string event );
	
	private uint source = 0;
	
	public WPACtrl() {
		this.open();
	}
	
	~WPACtrl() {
		this.close();
	}
	
	private void open() {
		this.close();
		
		// connect to wpa_supplicant
		this.wpa_ctrl_cmd = new WPAClient.WPACtrl( WPA_SUPPLICANT_SOCKET.printf( INTERFACE ) );
		this.wpa_ctrl_msg = new WPAClient.WPACtrl( WPA_SUPPLICANT_SOCKET.printf( INTERFACE ) );
		
		if(this.wpa_ctrl_cmd == null || this.wpa_ctrl_msg == null) warning("Connection to wpa_supplicant failed");
		
		// listen for unsolicited messages
		if(this.wpa_ctrl_msg != null) {
			if(this.wpa_ctrl_msg.attach()) {
				try {
					// add watch
					var channel = new IOChannel.unix_new(this.wpa_ctrl_msg.get_fd());
					channel.set_encoding(null);
					
					this.source = channel.add_watch(IOCondition.IN, this.receive);
					if(this.source == 0) {
						warning("Cannot add watch on IOChannel");
					}
				} catch ( IOChannelError e ) {
					warning("Cannot add watch on IOCHannel: %s", e.message);
				}
			}
		}
	}
	
	private void close() {
		if(this.wpa_ctrl_msg != null) this.wpa_ctrl_msg.detach();
		if(this.source > 0) Source.remove(this.source);
		this.wpa_ctrl_cmd = null;
		this.wpa_ctrl_msg = null;
	}
	
	private bool receive( IOChannel source, IOCondition condition ) {
		if(this.wpa_ctrl_msg == null) return Source.REMOVE;
		
		string? resp = this.wpa_ctrl_msg.recv();
		if(resp == null) {
			warning("Receive failed");
			return Source.REMOVE;
		}
		
		this.event( resp );
		
		return Source.CONTINUE;
	}
	
	public string request( string req ) throws WPACtrlError {
		if(this.wpa_ctrl_cmd == null) this.open();
		if(this.wpa_ctrl_cmd != null) {
			string? output = this.wpa_ctrl_cmd.request(req);
			if(output == null) {
				// retry once
				this.open();
				output = this.wpa_ctrl_cmd.request(req);
				if(output == null) throw new WPACtrlError.REQUEST_FAILED("Request failed");
			}
			return output;
		}else{
			throw new WPACtrlError.NOT_CONNECTED("Connection to wpa_supplicant failed");
		}
	}
	
}

public errordomain WPACtrlError {
	NOT_CONNECTED,
	REQUEST_FAILED
}