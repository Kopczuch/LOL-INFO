using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace ZBD.Models;

public partial class Bohaterowie
{
    [Key]
    [Required(ErrorMessage = "Nazwa jest wymagana.")]
    [StringLength(20, ErrorMessage = "Nazwa jest za długa.")]
    public string Nazwa { get; set; } = null!;

    [Required(ErrorMessage = "Tytuł jest wymagany.")]
    [StringLength(50, ErrorMessage = "Tytuł jest za długi.")]
    public string Tytuł { get; set; } = null!;

    [Required(ErrorMessage = "Opis jest wymagany.")]
    public string KrotkiOpis { get; set; } = null!;

    [Required, Range(0, 10, ErrorMessage = "Atak przyjmuje wartości pomiędzy 0 a 10")]
    public short Atak { get; set; }

    [Required, Range(0, 10, ErrorMessage = "Obrona przyjmuje wartości pomiędzy 0 a 10")]
    public short Obrona { get; set; }

    [Required, Range(0, 10, ErrorMessage = "Magia przyjmuje wartości pomiędzy 0 a 10")]
    public short Magia { get; set; }

    [Required, Range(0, 10, ErrorMessage = "Trudność przyjmuje wartości pomiędzy 0 a 10")]
    public short Trudnosc { get; set; }

    [Required(ErrorMessage = "Obraz jest wymagany.")]
    public string Obraz { get; set; } = null!;

    [Required(ErrorMessage = "Ikona jest wymagana.")]
    public string Ikona { get; set; } = null!;

    [Required(ErrorMessage = "Klasa jest wymagana.")]
    public string Klasa { get; set; } = null!;

    public virtual ICollection<GraczeZawodowi> GraczeZawodowis { get; } = new List<GraczeZawodowi>();

    public virtual ICollection<Gracze> Graczes { get; } = new List<Gracze>();

    public virtual ICollection<Gry> Gries { get; } = new List<Gry>();

    public virtual ICollection<Bohaterowie> Bohaters { get; } = new List<Bohaterowie>();

    public virtual ICollection<Bohaterowie> Kontras { get; } = new List<Bohaterowie>();
}
