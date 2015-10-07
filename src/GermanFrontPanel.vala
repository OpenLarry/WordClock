using WordClock;

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
	
	protected static uint8[,] WORDS = {
		{ 0,0 , 2 }, // 00 - ES
		{ 3,0 , 3 }, // 01 - IST
		{ 7,0 , 4 }, // 02 - FÜNF
		{ 0,1 , 4 }, // 03 - ZEHN
		{ 4,2 , 7 }, // 04 - VIERTEL
		{ 4,1 , 7 }, // 05 - ZWANZIG
		{ 0,4 , 4 }, // 06 - HALB
		{ 0,2 ,11 }, // 07 - DREIVIERTEL
		{ 6,3 , 3 }, // 08 - VOR
		{ 2,3 , 4 }, // 09 - NACH
		{ 2,5 , 3 }, // 10 - EIN
		{ 2,5 , 4 }, // 11 - EINS
		{ 0,5 , 4 }, // 12 - ZWEI
		{ 1,6 , 4 }, // 13 - DREI
		{ 7,7 , 4 }, // 14 - VIER
		{ 7,6 , 4 }, // 15 - FÜNF
		{ 1,9 , 5 }, // 16 - SECHS
		{ 5,5 , 6 }, // 17 - SIEBEN
		{ 1,8 , 4 }, // 18 - ACHT
		{ 3,7 , 4 }, // 19 - NEUN
		{ 5,8 , 4 }, // 20 - ZEHN
		{ 0,7 , 3 }, // 21 - ELF
		{ 5,4 , 5 }, // 22 - ZWÖLF
		{ 8,9 , 3 }, // 23 - UHR
	};
	
	public abstract uint8[,] getTime( uint8 hour, uint8 minute );
}