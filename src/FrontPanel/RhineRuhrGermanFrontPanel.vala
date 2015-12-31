using WordClock, Gee;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.RhineRuhrGermanFrontPanel : GermanFrontPanel {
	/**
	 * @param hour hour
	 * @param minute minute
	 * @return set of word positions
	 */
	public override HashSet<FrontPanel.WordPosition> getTime( uint8 hour, uint8 minute, bool display_it_is = true ) {
		GermanFrontPanel.Word[] words = {};
		
		if(display_it_is) {
			words += Word.ES;
			words += Word.IST;
		}
		
		switch(minute/5) {
			case 0: // 00
				words += Word.UHR;
			break;
			case 1: // 05
				words += Word.M_FUENF;
				words += Word.NACH;
			break;
			case 2: // 10
				words += Word.M_ZEHN;
				words += Word.NACH;
			break;
			case 3: // 15
				words += Word.M_VIERTEL;
				words += Word.NACH;
			break;
			case 4: // 20
				words += Word.M_ZWANZIG;
				words += Word.NACH;
			break;
			case 5: // 25
				words += Word.M_FUENF;
				words += Word.VOR;
				words += Word.M_HALB;
				hour++;
			break;
			case 6: // 30
				words += Word.M_HALB;
				hour++;
			break;
			case 7: // 35
				words += Word.M_FUENF;
				words += Word.NACH;
				words += Word.M_HALB;
				hour++;
			break;
			case 8: // 40
				words += Word.M_ZWANZIG;
				words += Word.VOR;
				hour++;
			break;
			case 9: // 45
				words += Word.M_VIERTEL;
				words += Word.VOR;
				hour++;
			break;
			case 10:// 50
				words += Word.M_ZEHN;
				words += Word.VOR;
				hour++;
			break;
			case 11:// 55
				words += Word.M_FUENF;
				words += Word.VOR;
				hour++;
			break;
		}
		
		
		hour = hour % 12;
		if(hour == 0) hour = 12;
		
		if(hour == 1 && (minute/5) == 0) {
			words += Word.H_EIN;
		}else{
			words += Word.H_EIN + hour;
		}
		
		HashSet<FrontPanel.WordPosition> ret = new HashSet<FrontPanel.WordPosition>();
		for(int i=0;i<words.length;i++) {
			ret.add(WORDS[words[i]]);
		}
		
		return ret;
	}
}
