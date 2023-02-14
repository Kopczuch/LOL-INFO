using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace ZBD.Models;

public partial class GraczeZawodowi
{
    [Key]
    [Required(ErrorMessage = "Nick jest wymagany.")]
    public string Nick { get; set; } = null!;

    [Required(ErrorMessage = "Imię i nazwisko są wymagane.")]
    public string ImieINazwisko { get; set; } = null!;

    [Required(ErrorMessage = "Kraj jest wymagany.")]
    public string Kraj { get; set; } = null!;

    [Required(ErrorMessage = "Rola jest wymagana.")]
    public string Rola { get; set; } = null!;

    [Required(ErrorMessage = "Rezydencja jest wymagana.")]
    public string Rezydencja { get; set; } = null!;

    public string? Zdjecie { get; set; }

    [Required(ErrorMessage = "Data urodzin jest wymagana.")]
    public DateTime DataUrodzin { get; set; }

    public string? IdDruzyny { get; set; }

    public string? UlubionyBohater { get; set; }

    public virtual Druzyny? IdDruzynyNavigation { get; set; }

    public virtual Bohaterowie? UlubionyBohaterNavigation { get; set; }

    public virtual ICollection<Gry> GryIdMeczus { get; } = new List<Gry>();
}
