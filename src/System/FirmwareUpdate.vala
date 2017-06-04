using WordClock;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.FirmwareUpdate : GLib.Object {
	private Subprocess? subprocess = null;
	
	private static bool running = false;
	
	public FirmwareUpdate() throws Error {
		if(running) throw new FirmwareUpdateError.IN_PROGRESS("Another update process is in progress!");
		running = true;
		
		debug("Start firmware update");
		
		this.subprocess = new Subprocess(SubprocessFlags.STDIN_PIPE | SubprocessFlags.INHERIT_FDS, "/usr/sbin/flashimage", "-p");
	}
	
	~FirmwareUpdate() {
		// destructor is called even if constructor threw an error
		if(this.subprocess != null) {
			running = false;
			
			this.abort();
		}
	}
	
	public void write_chunk( Bytes data ) throws Error {
		this.subprocess.get_stdin_pipe().write_bytes(data);
	}
	
	public void finish() throws Error {
		debug("Finish firmware update");
		
		this.subprocess.get_stdin_pipe().flush();
		this.subprocess.get_stdin_pipe().close();
	}
	
	public void abort() {
		debug("Abort firmware update");
		
		this.subprocess.force_exit();
	}
	
	public void wait_close() throws Error {
		debug("Wait for process termination");
		
		this.subprocess.wait_check();
		
		debug("Process ended");
	}
}

public errordomain WordClock.FirmwareUpdateError {
	IN_PROGRESS, WRITE_ERROR, READ_ERROR
}
