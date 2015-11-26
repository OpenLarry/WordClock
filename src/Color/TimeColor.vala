using WordClock;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.TimeColor : Color, Jsonable {
	public uint timespan = 60;
	
	private uint timeout = 0;
	
	public TimeColor() {
		this.set_timeout();
	}
	
	private void set_timeout() {
		this.timeout = GLib.Timeout.add_seconds(1, () => {
			this.hue_by_time( new DateTime.now_local() );
			return true;
		});
	}
	
	private void hue( int16 h ) {
		this.h = (this.h_perm + h) % 360;
		
		this.to_rgb();
		this.do_gamma_correction();
	}
	
	private void hue_by_time( DateTime time ) {
		uint seconds = time.get_hour() * 60 * 60 + time.get_minute() * 60 + time.get_second();
		
		uint offset = 0;
		if( (360/this.timespan) > 1 ) {
			offset = 360 * time.get_microsecond() / this.timespan / 1000000;
		}
		
		this.hue( (int16) (((seconds%this.timespan) * 360)/this.timespan + offset) );
	}
	
	public override Json.Node to_json( string path = "" ) throws JsonError {
		string subpath;
		string? property = JsonHelper.get_property( path, out subpath );
		
		if(property != null) {
			if(subpath!="") throw new JsonError.INVALID_PATH("Invalid path '%s'!".printf(subpath));
			
			if(property == "timespan") {
				Json.Node node = new Json.Node( Json.NodeType.VALUE );
				node.set_int( this.timespan );
				return node;
			}else{
				return base.to_json( path );
			}
		}else{
			Json.Node node = base.to_json( path );
			node.get_object().set_int_member( "timespan", this.timespan );
			
			return node;
		}
	}
	
	public override void from_json(Json.Node node, string path = "") throws JsonError {
		if(this.timeout == 0) this.set_timeout();
		
		string subpath;
		string? property = JsonHelper.get_property( path, out subpath );
		
		if(property != null) {
			if(subpath!="") throw new JsonError.INVALID_PATH("Invalid path '%s'!".printf(subpath));
			if( node.get_node_type() != Json.NodeType.VALUE ) throw new JsonError.INVALID_NODE_TYPE("Invalid node type! Value expected.");
			
			if(property == "timespan") {
				this.timespan = (uint) node.get_int();
			}else{
				base.from_json( node, path );
			}
		}else{
			if( node.get_node_type() != Json.NodeType.OBJECT ) throw new JsonError.INVALID_NODE_TYPE("Invalid node type! Object expected.");
			
			unowned Json.Object obj = node.get_object();
			if( obj.get_size() != 4 || !obj.has_member("timespan") ) throw new JsonError.INVALID_PROPERTY("Need property timespan!");
			if( obj.get_member("timespan").get_node_type() != Json.NodeType.VALUE ) throw new JsonError.INVALID_NODE_TYPE("Invalid node type! Value expected.");
			
			this.timespan = (uint) obj.get_int_member("timespan");
			
			obj.remove_member("timespan");
			
			base.from_json( node, path );
		}
	}
}
