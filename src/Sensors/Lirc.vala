/*
 * https://github.com/llamadonica/rhythmbox-remote/blob/master/src/lirc.vala
 *
 * lirc.vala
 * 
 * Copyright 2012 Adam Stark <astark@astark-laptop>
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
 * MA 02110-1301, USA.
 */
 
 using GLib;

namespace Lirc {
	//Sinc lirc client is a pretty small library, I figured it would
	//probably be worth my time to totally rewrite it so I can make
	//use of some f the features of Vala.
	
    public class Context : Object
    {
		public UnixSocketAddress socket_address { get; private set; }
		public string prog { get; private set;}
		public bool verbose { get; private set;}
		// Save the current lircd interface.
		public Context (string prog, bool verbose=false, string socket_path="/var/run/lirc/lircd") 
		{
			this.prog    = prog;
			this.verbose = verbose;
			this.socket_address = new UnixSocketAddress( socket_path );
		}
	}

	public class Listener : Object
	{
		private Socket socket;
		private Context con;
		
		public Listener(Context con, MainContext? loop_context = null) throws Error
		{
			
			this.con = con;
			this.socket = new Socket(SocketFamily.UNIX, SocketType.STREAM, SocketProtocol.DEFAULT);
			this.socket.connect( this.con.socket_address );
			
			if (loop_context != null)
			{
				// segmentation fault without casting! bug in glib?
				var socket_source_in = (SocketSource) this.socket.create_source (IOCondition.IN);
				socket_source_in.set_callback (this.listener_callback);
				socket_source_in.attach(loop_context);
			}
				
		}
		private bool listener_callback() 
		{
			if (!this.socket.is_closed())
			{
				var buffer = new uint8[2048]; //I can't imagine that anything would be longer than this.
				try
				{
					this.socket.receive(buffer);
				}
				catch (Error err)
				{
					return listener_dies();
				}
				if (this.con.verbose)
				{
					stderr.printf ("%s", (string) buffer);
				}
				uint8[] interpreted_key_code_buffer = new uint8[2048];
				uint8[]  device_conf_buffer = new uint8[2048];
				uint64 raw_key_code;
				uint8  repetition_number;
				
				if (((string) buffer).scanf("%Lx %hhx %2047s %2047s\n", out raw_key_code, out repetition_number, interpreted_key_code_buffer, device_conf_buffer) < 4) 
				{
					stderr.printf ("Error: unexpected pattern: %s: %s", this.con.prog, (string) buffer);
					return true;
				};
				
				string interpreted_key_code = (string) interpreted_key_code_buffer;
				string device_conf          = (string) device_conf_buffer;
				this.button (device_conf, interpreted_key_code, repetition_number);
			}
			else
			{
				return listener_dies();
			}
			return true;
		}
		private bool listener_dies ()
		{
			if (this.con.verbose)
			{
				stderr.printf ("%s\n",  "Communication with socket interupted. Closing now.");
			}
			this.died();
			return true;
		}
		public signal void button (string device_conf, string interpreted_key_code, uint8 repetition_number);
		public signal void died ();
		public void close ()
		{
			try
			{
				this.socket.close();
			}
			catch (Error e)
			{	//do nothing.
			}
		}
	}
/*
0000000087ee8a06 00 KEY_NEXT macmini.conf
*/
}
