using WordClock;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.WestGermanFrontPanel : GermanFrontPanel {
	public override uint8[,] getTime( uint8 hour, uint8 minute ) {
		GermanFrontPanel.Word[] words = {};
		
		words += Word.ES;
		words += Word.IST;
		
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
				words += Word.M_ZEHN;
				words += Word.VOR;
				words += Word.M_HALB;
				hour++;
			break;
			case 5: // 25
				words += Word.M_FUENF;
				words += Word.VOR;
				words += Word.M_HALB;
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
				words += Word.M_ZEHN;
				words += Word.NACH;
				words += Word.M_HALB;
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
		
		uint8[,] ret = new uint8[words.length,3];
		for(int i=0;i<words.length;i++) {
			ret[i,0] = WORDS[words[i],0];
			ret[i,1] = WORDS[words[i],1];
			ret[i,2] = WORDS[words[i],2];
		}
		
		return ret;
	}
}