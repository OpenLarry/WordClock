using WordClock, Gee;

/**
 * @author Aaron Larisch
 * @version 1.0
 */
namespace WordClock.Statistic {
	public uint16 min(AbstractList<uint16?> list) {
		if(list.size == 0) {
			return 0;
		}else{
			uint16? min = list.fold<uint16?>( (a,b) => { return (a<b) ? a : b; }, uint16.MAX );
			return min ?? 0;
		}
	}
	
	public uint16 max(AbstractList<uint16?> list) {
		if(list.size == 0) {
			return 0;
		}else{
			uint16? max = list.fold<uint16?>( (a,b) => { return (a>b) ? a : b; }, uint16.MIN );
			return max ?? 0;
		}
	}
	
	public uint16 mean(AbstractList<uint16?> list) {
		if(list.size == 0) {
			return 0;
		}else{
			uint? sum = list.fold<uint?>( (a,b) => { return a+b; }, 0 );
			return (uint16) ((sum ?? 0) / list.size);
		}
	}
	
	public uint16 median(AbstractList<uint16?> list) {
		if(list.size == 0) {
			return 0;
		}else{
			ArrayList<uint16?> array = new ArrayList<uint16?>();
			array.add_all(list);
			array.sort((a,b) => {
				return a-b;
			});
			
			if(list.size % 2 == 1) {
				return array[list.size/2];
			}else{
				return (array[list.size/2] + array[list.size/2-1]) / 2;
			}
		}
	}
}
