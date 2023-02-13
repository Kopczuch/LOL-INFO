using System;
using System.Collections.Generic;

namespace ZBD.Models;

public partial class Gry
{
    public long IdMeczu { get; set; }

    public string Rezultat { get; set; } = null!;

    public short Zabojstwa { get; set; }

    public short Smierci { get; set; }

    public short Asysty { get; set; }

    public short CreepScore { get; set; }

    public int ZdobyteZloto { get; set; }

    public TimeSpan CzasGry { get; set; }

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
