using WordClock;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.RestServer : Soup.Server {
	const uint16 PORT = 8080;
	
	private Settings settings;
	
	/**
	 * Creates a new HTTP REST server instance with JSON interface
	 * @param port Port number
	 * @param control LEDControl object which parses the request
	 */
	public RestServer( Settings settings ) throws GLib.Error {
		this.settings = settings;
		
		this.add_handler("/", request);
		
		this.listen_all(PORT, Soup.ServerListenOptions.IPV4_ONLY);
	}
	
	
	/**
	 * Callback method for requests from Soup.Server
	 * @param server Server instance
	 * @param msg Message instance
	 * @param path Requested path
	 * @param query Query parameters
	 * @param client Client instance
	 */
	public void request( Soup.Server server, Soup.Message msg, string path, HashTable? query, Soup.ClientContext client) {
		msg.response_headers.append("Access-Control-Allow-Origin", "*");
		msg.response_headers.append("Access-Control-Allow-Headers", "accept, content-type");
		msg.response_headers.append("Access-Control-Allow-Methods", "GET, POST, OPTIONS, PUT, DELETE");
		
		if(path == "/") {
			switch(msg.method) {
				case "GET":
					msg.set_response("text/html", Soup.MemoryUse.COPY, "<h1>It works</h1>!".data);
					msg.set_status(200);
				break;
				default:
					msg.set_status(405);
				break;
			}
		}else if( path == "/sensors" ) {
			switch(msg.method) {
				case "GET":
					
					string data = Json.gobject_to_data(Main.sensors, null);
					
					msg.set_response("application/json", Soup.MemoryUse.COPY, data.data);
					msg.set_status(200);
				break;
				default:
					msg.set_status(405);
				break;
			}
		}else if( path.index_of("/settings") == 0 ) {
			if(path == "/settings") {
				switch(msg.method) {
					case "GET":
						string data = Json.gobject_to_data(this.settings, null);
						
						msg.set_response("application/json", Soup.MemoryUse.COPY, data.data);
						msg.set_status(200);
					break;
					default:
						msg.set_status(405);
					break;
				}
			}else{
				string[] part = path.split("/");
				if(part.length < 5) {
					msg.set_status(404);
					return;
				}
				string class_name = "WordClock";
				for(int i=part.length-2;i>1;i--) class_name += part[i].substring(0,1).up()+part[i].substring(1).down();
				
				string schema_name = "";
				for(int i=2;i<part.length-1;i++) schema_name += ((i!=2)?".":"")+part[i].down();
				
				string settings_name = part[part.length-1];
			
				switch(msg.method) {
					case "GET":
						GLib.Object obj = Object.new( Type.from_name( class_name ) );
						if( obj == null || !settings.add_object( obj, settings_name ) ) {
							msg.set_response("text/plain", Soup.MemoryUse.COPY, "Class has no settings!".data);
							msg.set_status(400);
							return;
						}
						settings.remove_object( obj );
						
						string data = Json.gobject_to_data(obj, null);
						msg.set_response("application/json", Soup.MemoryUse.COPY, data.data);
						msg.set_status(200);
					break;
					case "PUT":
						if(msg.request_headers.get_content_type(null) == "application/json") {
							try{
								GLib.Object obj = Json.gobject_from_data( Type.from_name( class_name ), (string) msg.request_body.flatten().data);
								if( obj == null || !settings.add_object( obj, settings_name, GLib.SettingsBindFlags.SET ) ) {
									msg.set_response("text/plain", Soup.MemoryUse.COPY, "Class has no settings!".data);
									msg.set_status(400);
									return;
								}
								settings.remove_object( obj );
								
								msg.set_status(200);
							} catch( Error e ) {
								msg.set_response("text/plain", Soup.MemoryUse.COPY, e.message.data);
								msg.set_status(400);
							}
						}else{
							msg.set_status(415);
						}
					break;
					default:
						msg.set_status(405);
					break;
				}
			}
		}else{
			msg.set_status(404);
		}
	}
} 
