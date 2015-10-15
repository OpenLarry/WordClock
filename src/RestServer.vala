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
	public void request( Soup.Server server, Soup.Message msg, string path, HashTable? query, Soup.ClientContext client) {
		msg.response_headers.append("Access-Control-Allow-Origin", "*");
		msg.response_headers.append("Access-Control-Allow-Headers", "accept, content-type");
		msg.response_headers.append("Access-Control-Allow-Methods", "GET, POST, OPTIONS, PUT, DELETE");
		
		string subpath = "";
		
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
		}else if( path == "/vdd5v" ) {
			switch(msg.method) {
				case "GET":
					msg.set_response("text/plain", Soup.MemoryUse.COPY, Lradc.get_vdd5v().to_string().data);
					msg.set_status(200);
				break;
				default:
					msg.set_status(405);
				break;
			}
		}else if( path == "/temp" ) {
			switch(msg.method) {
				case "GET":
					msg.set_response("text/plain", Soup.MemoryUse.COPY, Lradc.get_temp().to_string().data);
					msg.set_status(200);
				break;
				default:
					msg.set_status(405);
				break;
			}
		}else if( path.scanf("/lradc/%s", subpath) == 1 ) {
			switch(msg.method) {
				case "GET":
					msg.set_response("text/plain", Soup.MemoryUse.COPY, Lradc.read(subpath).to_string().data);
					msg.set_status(200);
				break;
				default:
					msg.set_status(405);
				break;
			}
		}else{
			msg.set_status(405);
		}
	}
} 
