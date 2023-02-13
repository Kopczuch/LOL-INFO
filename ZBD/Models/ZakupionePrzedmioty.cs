using System;
using System.Collections.Generic;

namespace ZBD.Models;

public partial class ZakupionePrzedmioty
{
    public long Id { get; set; }

    public int IdPrzed { get; set; }

    public virtual Przedmioty IdPrzedNavigation { get; set; } = null!;

    public virtual ICollection<Gry> IdMeczus { get; } = new List<Gry>();
}
