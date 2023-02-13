using System;
using System.Collections.Generic;

namespace ZBD.Models;

public partial class Przedmioty
{
    public int IdPrzed { get; set; }

    public string Nazwa { get; set; } = null!;

    public string Statystyki { get; set; } = null!;

    public string Ikona { get; set; } = null!;

    public short? Cena { get; set; }

    public short? WartoscSprzedazy { get; set; }

    public virtual ICollection<GryZakupioneprzedmioty> GryZakupioneprzedmioties { get; } = new List<GryZakupioneprzedmioty>();

    public virtual ICollection<KomponentyPrzedmiotow> KomponentyPrzedmiotowIdKomponentuNavigations { get; } = new List<KomponentyPrzedmiotow>();

    public virtual ICollection<KomponentyPrzedmiotow> KomponentyPrzedmiotowIdPrzedNavigations { get; } = new List<KomponentyPrzedmiotow>();
}
