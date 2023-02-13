using System;
using System.Collections.Generic;

namespace ZBD.Models;

public partial class GryZakupioneprzedmioty
{
    public long Id { get; set; }

    public long IdMeczu { get; set; }

    public int IdZakupionegoPrzedmiotu { get; set; }

    public virtual Gry IdMeczuNavigation { get; set; } = null!;

    public virtual Przedmioty IdZakupionegoPrzedmiotuNavigation { get; set; } = null!;
}
