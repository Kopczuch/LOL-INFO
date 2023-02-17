using System.ComponentModel.DataAnnotations;

namespace ZBD.Models
{
    public partial class LoginDetails
    {
        [Required(ErrorMessage="Nazwa użytkownika jest wymagana.")]
        [StringLength(20, ErrorMessage = "Nazwa użytkownika jest zbyt długa.")]
        public string UserName { get; set; }
        [Required(ErrorMessage="Hasło jest wymagane.")]
        [StringLength(100, ErrorMessage = "Hasło jest zbyt długie.")]
        public string Password { get; set; }
    }
}
