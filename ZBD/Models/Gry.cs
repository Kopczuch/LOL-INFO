using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace ZBD.Models;

public partial class Gry
{
    public long IdMeczu { get; set; }

    [Required (ErrorMessage = "Rezultat jest wymagany.")]
    public string Rezultat { get; set; } = null!;

    [Required (ErrorMessage = "Liczba zabójstw jest wymagana.")]
    [Range(0, short.MaxValue, ErrorMessage = "Liczba zabójstw przyjmuje tylko wartości nieujemne.")]
    public short Zabojstwa { get; set; }

    [Required(ErrorMessage = "Liczba śmierci jest wymagana.")]
    [Range(0, short.MaxValue, ErrorMessage = "Liczba śmierci przyjmuje tylko wartości nieujemne.")]
    public short Smierci { get; set; }

    [Required(ErrorMessage = "Liczba asyst jest wymagana.")]
    [Range(0, short.MaxValue, ErrorMessage = "Liczba asyst przyjmuje tylko wartości nieujemne.")]
    public short Asysty { get; set; }

    [Required(ErrorMessage = "Creep score jest wymagany.")]
    [Range(0, short.MaxValue, ErrorMessage = "Creep Score przyjmuje tylko wartości nieujemne.")]
    public short CreepScore { get; set; }

    [Required(ErrorMessage = "Zdobyte złoto jest wymagane.")]
    [Range(0, int.MaxValue, ErrorMessage = "Zdobyte złoto przyjmuje tylko wartości nieujemne.")]
    public int ZdobyteZloto { get; set; }

    [Required]
    public TimeSpan CzasGry { get; set; }

    [Required(ErrorMessage = "Zadane obrażenia są wymagane.")]
    [Range(0, int.MaxValue, ErrorMessage = "Zadane obrażenia przyjmują tylko wartości nieujemne.")]
    public int ZadaneObrazenia { get; set; }

    public short? ZabojstwaDruzyny { get; set; }

    public short? ZgonyDruzyny { get; set; }

    public string? Strona { get; set; }

    public string? BohaterowieNazwa { get; set; }

    public virtual Bohaterowie? BohaterowieNazwaNavigation { get; set; }

    public virtual ICollection<GryZakupioneprzedmioty> GryZakupioneprzedmioties { get; } = new List<GryZakupioneprzedmioty>();

    public virtual ICollection<Gracze> GraczeNicks { get; } = new List<Gracze>();

    public virtual ICollection<GraczeZawodowi> GraczeZawodowiNicks { get; } = new List<GraczeZawodowi>();
}
