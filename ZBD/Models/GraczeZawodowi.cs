using System;
using System.Collections.Generic;

namespace ZBD.Models;

public partial class GraczeZawodowi
{
    public string Nick { get; set; } = null!;

    public string ImieINazwisko { get; set; } = null!;

    public string Kraj { get; set; } = null!;

    public string Rola { get; set; } = null!;

    public string Rezydencja { get; set; } = null!;

    public string? Zdjecie { get; set; }

    public DateTime? DataUrodzin { get; set; }

    public string? IdDruzyny { get; set; }

    public string? UlubionyBohater { get; set; }

    public virtual Druzyny? IdDruzynyNavigation { get; set; }

    public virtual Bohaterowie? UlubionyBohaterNavigation { get; set; }

    public virtual ICollection<Gry> GryIdMeczus { get; } = new List<Gry>();
}
