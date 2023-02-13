using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace ZBD.Models;

public partial class Gracze
{
    [Key]
    public string Nick { get; set; } = null!;

    [Required (ErrorMessage = "Dywizja jest wymagana.")]
    public string Dywizja { get; set; } = null!;

    [Required, Range(1, short.MaxValue, ErrorMessage = "Poziom przyjmuje wartości >= 1")]
    public short Poziom { get; set; }

    public string? UlubionyBohater { get; set; }

    public virtual DaneLogowanium? DaneLogowanium { get; set; }

    public virtual Bohaterowie? UlubionyBohaterNavigation { get; set; }

    public virtual ICollection<Gry> GryIdMeczus { get; } = new List<Gry>();
}
