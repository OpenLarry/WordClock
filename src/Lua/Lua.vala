using WordClock, Lua, Gee;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.Lua : GLib.Object, Jsonable {
	public string script {
		get {
			return this._script;
		}
		set {
			if(this.vm != null && this._script != value) {
				this._script = value;
				try {
					this.run();
				}catch(LuaError e) {
					stderr.printf("Lua error: %s\n", e.message);
				}
			}else{
				this._script = value;
			}
		}
		default = "/etc/wordclock/script.lua";
	}
	private string _script = "";
	public uint log_size { get; set; default = 50; }
	
	protected LuaVM vm;
	
	public signal void init();
	public signal void deinit();
	public signal void message(string message);
	
	private LinkedList<string> log = new LinkedList<string>();
	private static TreeMap<unowned LuaVM,Lua> this_map = new TreeMap<unowned LuaVM,Lua>();
	
	
	~Lua() {
		this.deinit();
		this_map.unset(this.vm);
	}
	
	public void run() throws LuaError {
		lock(this.vm) {
			// destroy old lua instance
			if(this.vm != null) {
				this.deinit();
				
				this_map.unset(this.vm);
			}
			
			// new lua instance
			this.vm = new LuaVM();
			this_map[this.vm] = this;
			
			this.vm.open_libs();
			
			// overwrite print function for remote debugging
			this.register_func("print", print);
			
			this.init();
			
			// run script
			if(this.vm.do_file(this.script)) {
				Value error = Value(typeof(string));
				this.pop_value(ref error);
				this.log_message((string) error);
				throw new LuaError.SCRIPT_ERROR((string) error);
			}else{
				this.log_message("Lua script %s loaded!".printf(this.script));
				stdout.printf("Lua script %s loaded!\n",this.script);
			}
		}
	}
	
	public void register_func(string name, CallbackFunc func) {
		this.vm.register(name, func);
	}
	
	public void call_function( string func, Value[] params = {}, Value[] ret = {} ) throws LuaError {
		lock(this.vm) {
			this.vm.get_global(func);
			foreach(Value param in params) this.push_value(param);
			
			if(this.vm.pcall(params.length, ret.length) != 0) {
				Value error = Value(typeof(string));
				this.pop_value(ref error);
				this.log_message((string) error);
				throw new LuaError.CALL_ERROR((string) error);
			}else{
				for(uint i=0;i<ret.length;i++) {
					this.pop_value(ref ret[i]);
				}
			}
		}
	}
	
	public bool push_value( Value val ) {
		if(val.type().is_object()) {
			if(val.get_object() == null) {
				this.vm.push_nil();
			}else{
				stderr.puts("Can't push object on lua stack!\n");
				return false;
			}
		}else{
			if(val.holds(typeof(bool))) {
				this.vm.push_boolean( val.get_boolean() ? 1 : 0 );
			}else if(val.holds(typeof(char))) {
				this.vm.push_integer( val.get_schar() );
			}else if(val.holds(typeof(uchar))) {
				this.vm.push_integer( val.get_uchar() );
			}else if(val.holds(typeof(int))) {
				this.vm.push_integer( val.get_int() );
			}else if(val.holds(typeof(uint))) {
				this.vm.push_integer( (int) val.get_uint() );
			}else if(val.holds(typeof(long))) {
				this.vm.push_integer( (int) val.get_long() );
			}else if(val.holds(typeof(ulong))) {
				this.vm.push_integer( (int) val.get_ulong() );
			}else if(val.holds(typeof(int64))) {
				this.vm.push_integer( (int) val.get_int64() );
			}else if(val.holds(typeof(uint64))) {
				this.vm.push_integer( (int) val.get_uint64() );
			}else if(val.holds(typeof(float))) {
				this.vm.push_number( val.get_float() );
			}else if(val.holds(typeof(double))) {
				this.vm.push_number( val.get_double() );
			}else if(val.holds(typeof(string))) {
				this.vm.push_string( val.get_string() );
			}else{
				stderr.puts("Can't push unknown value type on lua stack!\n");
				return false;
			}
		}
		
		return true;
	}
	
	public bool pop_value( ref Value val ) {
		if(this.vm.is_number(-1) && val.holds(typeof(double))) {
			val.set_double(this.vm.to_number(-1));
		}else if(this.vm.is_number(-1) && val.holds(typeof(int))) {
			val.set_int(this.vm.to_integer(-1));
		}else if(this.vm.is_boolean(-1) && val.holds(typeof(bool))) {
			val.set_boolean(this.vm.to_boolean(-1));
		}else if(this.vm.is_string(-1) && val.holds(typeof(string))) {
			val.set_string(this.vm.to_string(-1));
		}else{
			stderr.printf("Can't pop return value from lua stack into %s variable!\n", val.type().name());
			return false;
		}
		
		this.vm.pop(-1);
		
		return true;
	}
	
	public bool write_script(string script) throws Error {
		var file = GLib.File.new_for_path( this.script );
		var ostream = file.replace(null, true, FileCreateFlags.REPLACE_DESTINATION);
		var dostream = new GLib.DataOutputStream( ostream );
		dostream.put_string(script);
		
		return true;
	}
	
	public string read_script() throws Error {
		var file = GLib.File.new_for_path( this.script );
		var istream = file.read();
		var dis = new GLib.DataInputStream( istream );
		
		return dis.read_upto("",0,null);
	}
	
	public void log_message( string message ) {
		string format_message = "%s: %s".printf(new DateTime.now(Main.timezone).format("%c"), message);
		this.log.add(format_message);
		
		if(this.log.size > this.log_size) this.log.poll_head();
		this.message(format_message);
	}
	
	public string get_log() {
		return this.log.fold<string>( (a,b) => { return b+a+"\n"; }, "" );
	}
	
	private static int print( LuaVM vm ) {
		Lua that = this_map[vm];
		
		string output = "";
		for(int i=1;i<=vm.get_top();i++) {
			if(vm.is_string(i)) {
				output += vm.to_string(i);
			}
		}
		
		that.log_message(output);
		stdout.printf("%s\n", output);
		
		return 0;
	}
}

public errordomain WordClock.LuaError {
	SCRIPT_ERROR, CALL_ERROR
}
