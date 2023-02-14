using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace ZBD.Models;

public partial class Przedmioty
{
    [Key]
    public int IdPrzed { get; set; }

    [Required (ErrorMessage = "Nazwa jest wymagana.")]
    [StringLength(60, ErrorMessage = "Nazwa jest za długa.")]
    public string Nazwa { get; set; } = null!;

    [Required(ErrorMessage = "Statystyki są wymagane.")]
    public string Statystyki { get; set; } = null!;

    [Required(ErrorMessage = "Ikona jest wymagana.")]
    public string Ikona { get; set; } = null!;

    [Required, Range(0, int.MaxValue, ErrorMessage = "Cena przyjmuje tylko wartości nieujemne.")]
    public short? Cena { get; set; }

    [Required (ErrorMessage = "Wartość sprzedaży jest wymagana."), Range(0, int.MaxValue, ErrorMessage = "Wartość sprzedaży przyjmuje tylko wartości nieujemne.")]
    public short? WartoscSprzedazy { get; set; }

    public virtual ICollection<GryZakupioneprzedmioty> GryZakupioneprzedmioties { get; } = new List<GryZakupioneprzedmioty>();

    public virtual ICollection<KomponentyPrzedmiotow> KomponentyPrzedmiotowIdKomponentuNavigations { get; } = new List<KomponentyPrzedmiotow>();

    public virtual ICollection<KomponentyPrzedmiotow> KomponentyPrzedmiotowIdPrzedNavigations { get; } = new List<KomponentyPrzedmiotow>();
}
