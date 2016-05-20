using WordClock;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.RestServer : Soup.Server {
	const uint16 PORT = 8080;
	
	/**
	 * Creates a new HTTP REST server instance with JSON interface
	 * @param port Port number
	 * @param control LEDControl object which parses the request
	 */
	public RestServer( ) throws GLib.Error {
		
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
	public void request( Soup.Server server, Soup.Message msg, string path, HashTable<string,string>? query, Soup.ClientContext client) {
		msg.response_headers.append("Access-Control-Allow-Origin", "*");
		msg.response_headers.append("Access-Control-Allow-Headers", "accept, content-type");
		msg.response_headers.append("Access-Control-Allow-Methods", "GET, POST, OPTIONS, PUT, DELETE");
		
		if(msg.method == "OPTIONS") {
			msg.set_status(200);
			return;
		}
		
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
		}else if( path == "/hwinfo" ) {
			switch(msg.method) {
				case "GET":
					try{
						string data = JsonHelper.to_string(Main.hwinfo.to_json());
						
						msg.set_response("application/json", Soup.MemoryUse.COPY, data.data);
						msg.set_status(200);
					} catch( Error e ) {
						msg.set_response("text/plain", Soup.MemoryUse.COPY, e.message.data);
						msg.set_status(400);
					}
				break;
				default:
					msg.set_status(405);
				break;
			}
		}else if( path.index_of("/settings") == 0 ) {
				switch(msg.method) {
					case "GET":
						try{
							string data = JsonHelper.to_string( Main.settings.to_json( path.substring(9) ) );
							msg.set_response("application/json", Soup.MemoryUse.COPY, data.data);
							
							msg.set_status(200);
						} catch( Error e ) {
							msg.set_response("text/plain", Soup.MemoryUse.COPY, e.message.data);
							msg.set_status(400);
						}
					break;
					case "PUT":
						try{
							Main.settings.from_json( JsonHelper.from_string( (string) msg.request_body.flatten().data ), path.substring(9) );
							
							// save immediately if complete configuration is updated
							if(path.substring(9) == "") {
								Main.settings.save();
							}else{
								Main.settings.deferred_save();
							}
							
							msg.set_response("application/json", Soup.MemoryUse.COPY, "true".data);
							msg.set_status(200);
						} catch( Error e ) {
							msg.set_response("text/plain", Soup.MemoryUse.COPY, e.message.data);
							msg.set_status(400);
						}
					break;
					default:
						msg.set_status(405);
					break;
				}
			// }
		}else{
			msg.set_status(404);
		}
	}
} 
