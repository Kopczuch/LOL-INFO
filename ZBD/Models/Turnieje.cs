using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace ZBD.Models;

public partial class Turnieje
{
    [Required (ErrorMessage = "Nazwa jest wymagana.")]
    public string NazwaTurnieju { get; set; } = null!;

    [Required (ErrorMessage = "Rodzaj jest wymagany.")]
    public string Rodzaj { get; set; } = null!;

    [Required (ErrorMessage = "Data jest wymagana.")]
    public DateTime Data { get; set; }

    [Required (ErrorMessage = "Miejsce jest wymagane.")]
    public short ZajeteMiejsce { get; set; }

    [Required (ErrorMessage = "Ostatni wynik jest wymagany.")]
    public string OstatniWynik { get; set; } = null!;

    [Range(0, double.MaxValue, ErrorMessage = "Nagroda nie może być ujemna.")]
    public decimal? Nagroda { get; set; }

    [Required (ErrorMessage = "ID drużyny jest wymagane.")]
    public string IdDruzyny { get; set; } = null!;

    public virtual Druzyny IdDruzynyNavigation { get; set; } = null!;
}
