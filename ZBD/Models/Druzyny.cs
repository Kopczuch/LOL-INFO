using System;
using System.Collections.Generic;

namespace ZBD.Models;

public partial class Druzyny
{
    public string IdDruzyny { get; set; } = null!;

    public string Nazwa { get; set; } = null!;

    public string Opis { get; set; } = null!;

    public string Liga { get; set; } = null!;

    public string Logo { get; set; } = null!;

    public string? ZdjecieZawodnikow { get; set; }

    public virtual ICollection<GraczeZawodowi> GraczeZawodowis { get; } = new List<GraczeZawodowi>();

    public virtual ICollection<Turnieje> Turniejes { get; } = new List<Turnieje>();
}
