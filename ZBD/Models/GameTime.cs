using System.ComponentModel.DataAnnotations;

namespace ZBD.Models
{
	public class GameTime
	{
        [Range(0, 2, ErrorMessage = "Godziny przyjmują wartości od 0 do 2.")]
        public int hours;
        [Range(0, 59, ErrorMessage = "Minuty przyjmują wartości od 0 do 59.")]
        public int minutes;
        [Range(0, 59, ErrorMessage = "Sekundy przyjmują wartości od 0 do 59.")]
        public int seconds;
    }
}
