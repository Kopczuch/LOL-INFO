using System;
using System.Collections.Generic;

namespace ZBD.Models;

public partial class DaneLogowanium
{
    public string Nick { get; set; } = null!;

    public string Haslo { get; set; } = null!;

    public string Rola { get; set; } = null!;

    public virtual Gracze NickNavigation { get; set; } = null!;
}
