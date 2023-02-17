using System.ComponentModel.DataAnnotations;

namespace ZBD.Models
{
    public partial class RegisterDetails
    {
        [Required(ErrorMessage = "Nazwa użytkownika jest wymagana.")]
        [StringLength(20, ErrorMessage = "Nazwa użytkownika jest zbyt długa.")]
        public string UserName { get; set; }
        [Required(ErrorMessage = "Hasło jest wymagane.")]
        [StringLength(100, ErrorMessage = "Hasło jest zbyt długie.")]
        public string Password { get; set; }
        [Required(ErrorMessage = "Dywizja jest wymagana.")]
        public string Dywizja { get; set; } = null!;
        [Required, Range(1, short.MaxValue, ErrorMessage = "Poziom przyjmuje tylko wartości dodatnie")]
        public short Poziom { get; set; }
        public string? UlubionyBohater { get; set; }
    }
}
