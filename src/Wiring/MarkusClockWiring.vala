using WordClock;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
public class WordClock.MarkusClockWiring : GLib.Object, ClockWiring {
	
	public Color[,] get_matrix( Color[,] leds ) {
		return {
			{ // col 00
				leds[2,30], // row 0
				leds[2,31], // row 1
				leds[2,32], // row 2
				leds[2,33], // row 3
				leds[2,34], // row 4
				leds[2,35], // row 5
				leds[2,36], // row 6
				leds[2,37], // row 7
				leds[2,38], // row 8
				leds[2,39], // row 9
			},{ // col 01
				leds[2,49],
				leds[2,48],
				leds[2,47],
				leds[2,46],
				leds[2,45],
				leds[2,44],
				leds[2,43],
				leds[2,42],
				leds[2,41],
				leds[2,40],
			},{ // col 02
				leds[2,50],
				leds[2,51],
				leds[2,52],
				leds[2,53],
				leds[2,54],
				leds[2,55],
				leds[2,56],
				leds[2,57],
				leds[2,58],
				leds[2,59],
			},{ // col 03
				leds[1,30],
				leds[1,31],
				leds[1,32],
				leds[1,33],
				leds[1,34],
				leds[1,35],
				leds[1,36],
				leds[1,37],
				leds[1,38],
				leds[1,39],
			},{ // col 04
				leds[1,49],
				leds[1,48],
				leds[1,47],
				leds[1,46],
				leds[1,45],
				leds[1,44],
				leds[1,43],
				leds[1,42],
				leds[1,41],
				leds[1,40],
			},{ // col 05
				leds[1,50],
				leds[1,51],
				leds[1,52],
				leds[1,53],
				leds[1,54],
				leds[1,55],
				leds[1,56],
				leds[1,57],
				leds[1,58],
				leds[1,59],
			},{ // col 06
				leds[0,44],
				leds[0,45],
				leds[0,46],
				leds[0,47],
				leds[0,48],
				leds[0,49],
				leds[0,50],
				leds[0,51],
				leds[0,52],
				leds[0,53],
			},{ // col 07
				leds[0,43],
				leds[0,42],
				leds[0,41],
				leds[0,40],
				leds[0,39],
				leds[0,38],
				leds[0,37],
				leds[0,36],
				leds[0,35],
				leds[0,34],
			},{ // col 08
				leds[0,24],
				leds[0,25],
				leds[0,26],
				leds[0,27],
				leds[0,28],
				leds[0,29],
				leds[0,30],
				leds[0,31],
				leds[0,32],
				leds[0,33],
			},{ // col 09
				leds[0,23],
				leds[0,22],
				leds[0,21],
				leds[0,20],
				leds[0,19],
				leds[0,18],
				leds[0,17],
				leds[0,16],
				leds[0,15],
				leds[0,14],
			},{ // col 10
				leds[0, 4],
				leds[0, 5],
				leds[0, 6],
				leds[0, 7],
				leds[0, 8],
				leds[0, 9],
				leds[0,10],
				leds[0,11],
				leds[0,12],
				leds[0,13],
			}
		};
	}
	
	public Color[] get_dots( Color[,] leds ) {
		return {
			leds[0,3],
			leds[0,2],
			leds[0,1],
			leds[0,0],
		};
	}
	
	public Color[] get_backlight( Color[,] leds ) {
		return {
			leds[1,22],
			leds[1,21],
			leds[1,20],
			leds[1,19],
			leds[1,18],
			leds[1,17],
			leds[1,16],
			leds[1,15],
			leds[1,14],
			leds[1,13],
			leds[1,12],
			leds[1,11],
			leds[1,10],
			leds[1, 9],
			leds[1, 8],
			leds[1, 7],
			leds[1, 6],
			leds[1, 5],
			leds[1, 4],
			leds[1, 3],
			leds[1, 2],
			leds[1, 1],
			leds[1, 0],
			leds[2, 0],
			leds[2, 1],
			leds[2, 2],
			leds[2, 3],
			leds[2, 4],
			leds[2, 5],
			leds[2, 6],
			leds[2, 7],
			leds[2, 8],
			leds[2, 9],
			leds[2,10],
			leds[2,11],
			leds[2,12],
			leds[2,13],
			leds[2,14],
			leds[2,15],
			leds[2,16],
			leds[2,17],
			leds[2,18],
			leds[2,19],
			leds[2,20],
			leds[2,21],
			leds[2,22],
			leds[2,23],
			leds[2,24],
			leds[2,25],
			leds[2,26],
			leds[2,27],
			leds[2,28],
			leds[2,29],
			leds[1,29],
			leds[1,28],
			leds[1,27],
			leds[1,26],
			leds[1,25],
			leds[1,24],
			leds[1,23],
		};
	}
}
