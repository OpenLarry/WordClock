using WordClock, Gee;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public abstract class WordClock.GermanFrontPanel : GLib.Object, FrontPanel {
	protected enum Word {
		ES,
		IST,
		M_FUENF,
		M_ZEHN,
		M_VIERTEL,
		M_ZWANZIG,
		M_HALB,
		M_DREIVIERTEL,
		VOR,
		NACH,
		H_EIN,
		H_EINS,
		H_ZWEI,
		H_DREI,
		H_VIER,
		H_FUENF,
		H_SECHS,
		H_SIEBEN,
		H_ACHT,
		H_NEUN,
		H_ZEHN,
		H_ELF,
		H_ZWOELF,
		UHR,
	}
	
	protected static FrontPanel.WordPosition[] WORDS = {
		new FrontPanel.WordPosition() { x=0,y=0,length= 2 }, // 00 - ES
		new FrontPanel.WordPosition() { x=3,y=0,length= 3 }, // 01 - IST
		new FrontPanel.WordPosition() { x=7,y=0,length= 4 }, // 02 - FÜNF
		new FrontPanel.WordPosition() { x=0,y=1,length= 4 }, // 03 - ZEHN
		new FrontPanel.WordPosition() { x=4,y=2,length= 7 }, // 04 - VIERTEL
		new FrontPanel.WordPosition() { x=4,y=1,length= 7 }, // 05 - ZWANZIG
		new FrontPanel.WordPosition() { x=0,y=4,length= 4 }, // 06 - HALB
		new FrontPanel.WordPosition() { x=0,y=2,length=11 }, // 07 - DREIVIERTEL
		new FrontPanel.WordPosition() { x=6,y=3,length= 3 }, // 08 - VOR
		new FrontPanel.WordPosition() { x=2,y=3,length= 4 }, // 09 - NACH
		new FrontPanel.WordPosition() { x=2,y=5,length= 3 }, // 10 - EIN
		new FrontPanel.WordPosition() { x=2,y=5,length= 4 }, // 11 - EINS
		new FrontPanel.WordPosition() { x=0,y=5,length= 4 }, // 12 - ZWEI
		new FrontPanel.WordPosition() { x=1,y=6,length= 4 }, // 13 - DREI
		new FrontPanel.WordPosition() { x=7,y=7,length= 4 }, // 14 - VIER
		new FrontPanel.WordPosition() { x=7,y=6,length= 4 }, // 15 - FÜNF
		new FrontPanel.WordPosition() { x=1,y=9,length= 5 }, // 16 - SECHS
		new FrontPanel.WordPosition() { x=5,y=5,length= 6 }, // 17 - SIEBEN
		new FrontPanel.WordPosition() { x=1,y=8,length= 4 }, // 18 - ACHT
		new FrontPanel.WordPosition() { x=3,y=7,length= 4 }, // 19 - NEUN
		new FrontPanel.WordPosition() { x=5,y=8,length= 4 }, // 20 - ZEHN
		new FrontPanel.WordPosition() { x=0,y=7,length= 3 }, // 21 - ELF
		new FrontPanel.WordPosition() { x=5,y=4,length= 5 }, // 22 - ZWÖLF
		new FrontPanel.WordPosition() { x=8,y=9,length= 3 }, // 23 - UHR
	};
	
	public abstract HashSet<FrontPanel.WordPosition> getTime( uint8 hour, uint8 minute, bool display_it_is = true );
}
