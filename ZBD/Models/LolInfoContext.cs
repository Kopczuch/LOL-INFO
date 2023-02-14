using System;
using System.Collections.Generic;
using Microsoft.EntityFrameworkCore;

namespace ZBD.Models;

public partial class LolInfoContext : DbContext
{
    public LolInfoContext()
    {
    }

    public LolInfoContext(DbContextOptions<LolInfoContext> options)
        : base(options)
    {
    }

    public virtual DbSet<Bohaterowie> Bohaterowies { get; set; }

    public virtual DbSet<DaneLogowanium> DaneLogowania { get; set; }

    public virtual DbSet<Druzyny> Druzynies { get; set; }

    public virtual DbSet<Gracze> Graczes { get; set; }

    public virtual DbSet<GraczeZawodowi> GraczeZawodowis { get; set; }

    public virtual DbSet<Gry> Gries { get; set; }

    public virtual DbSet<GryZakupioneprzedmioty> GryZakupioneprzedmioties { get; set; }

    public virtual DbSet<KomponentyPrzedmiotow> KomponentyPrzedmiotows { get; set; }

    public virtual DbSet<Przedmioty> Przedmioties { get; set; }

    public virtual DbSet<Turnieje> Turniejes { get; set; }

    protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
#warning To protect potentially sensitive information in your connection string, you should move it out of source code. You can avoid scaffolding the connection string by using the Name= syntax to read it from configuration - see https://go.microsoft.com/fwlink/?linkid=2131148. For more guidance on storing connection strings, see http://go.microsoft.com/fwlink/?LinkId=723263.
        => optionsBuilder.UseSqlServer("Data Source=PC\\SQLEXPRESS;Database=lolinfo;Integrated Security=True;Connect Timeout=30;Encrypt=False;TrustServerCertificate=False;ApplicationIntent=ReadWrite;MultiSubnetFailover=False");

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<Bohaterowie>(entity =>
        {
            entity.HasKey(e => e.Nazwa).HasName("bohaterowie_pk");

            entity.ToTable("bohaterowie");

            entity.HasIndex(e => e.Nazwa, "bohaterowie__idx");

            entity.Property(e => e.Nazwa)
                .HasMaxLength(20)
                .IsUnicode(false)
                .HasColumnName("nazwa");
            entity.Property(e => e.Atak).HasColumnName("atak");
            entity.Property(e => e.Ikona)
                .IsUnicode(false)
                .HasColumnName("ikona");
            entity.Property(e => e.Klasa)
                .HasMaxLength(20)
                .IsUnicode(false)
                .HasColumnName("klasa");
            entity.Property(e => e.KrotkiOpis)
                .IsUnicode(false)
                .HasColumnName("krotki_opis");
            entity.Property(e => e.Magia).HasColumnName("magia");
            entity.Property(e => e.Obraz)
                .IsUnicode(false)
                .HasColumnName("obraz");
            entity.Property(e => e.Obrona).HasColumnName("obrona");
            entity.Property(e => e.Trudnosc).HasColumnName("trudnosc");
            entity.Property(e => e.Tytuł)
                .HasMaxLength(30)
                .IsUnicode(false)
                .HasColumnName("tytuł");

            entity.HasMany(d => d.Bohaters).WithMany(p => p.Kontras)
                .UsingEntity<Dictionary<string, object>>(
                    "Kontry",
                    r => r.HasOne<Bohaterowie>().WithMany()
                        .HasForeignKey("Bohater")
                        .HasConstraintName("kontry_bohaterowie_fk"),
                    l => l.HasOne<Bohaterowie>().WithMany()
                        .HasForeignKey("Kontra")
                        .OnDelete(DeleteBehavior.ClientSetNull)
                        .HasConstraintName("kontry_bohaterowie_fkv1"),
                    j =>
                    {
                        j.HasKey("Bohater", "Kontra").HasName("kontry_pk");
                        j.ToTable("kontry");
                    });

            entity.HasMany(d => d.Kontras).WithMany(p => p.Bohaters)
                .UsingEntity<Dictionary<string, object>>(
                    "Kontry",
                    r => r.HasOne<Bohaterowie>().WithMany()
                        .HasForeignKey("Kontra")
                        .OnDelete(DeleteBehavior.ClientSetNull)
                        .HasConstraintName("kontry_bohaterowie_fkv1"),
                    l => l.HasOne<Bohaterowie>().WithMany()
                        .HasForeignKey("Bohater")
                        .HasConstraintName("kontry_bohaterowie_fk"),
                    j =>
                    {
                        j.HasKey("Bohater", "Kontra").HasName("kontry_pk");
                        j.ToTable("kontry");
                    });
        });

        modelBuilder.Entity<DaneLogowanium>(entity =>
        {
            entity.HasKey(e => e.Nick).HasName("dane_logowania_pk");

            entity.ToTable("dane_logowania");

            entity.Property(e => e.Nick)
                .HasMaxLength(20)
                .IsUnicode(false)
                .HasColumnName("nick");
            entity.Property(e => e.Haslo)
                .HasMaxLength(100)
                .IsUnicode(false)
                .HasColumnName("haslo");
            entity.Property(e => e.Rola)
                .HasMaxLength(30)
                .IsUnicode(false)
                .HasColumnName("rola");

            entity.HasOne(d => d.NickNavigation).WithOne(p => p.DaneLogowanium)
                .HasForeignKey<DaneLogowanium>(d => d.Nick)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("dane_logowania_gracze_fk");
        });

        modelBuilder.Entity<Druzyny>(entity =>
        {
            entity.HasKey(e => e.IdDruzyny).HasName("druzyny_pk");

            entity.ToTable("druzyny");

            entity.Property(e => e.IdDruzyny)
                .HasMaxLength(6)
                .IsUnicode(false)
                .HasColumnName("id_druzyny");
            entity.Property(e => e.Liga)
                .HasMaxLength(20)
                .IsUnicode(false)
                .HasColumnName("liga");
            entity.Property(e => e.Logo)
                .IsUnicode(false)
                .HasColumnName("logo");
            entity.Property(e => e.Nazwa)
                .HasMaxLength(50)
                .IsUnicode(false)
                .HasColumnName("nazwa");
            entity.Property(e => e.Opis)
                .IsUnicode(false)
                .HasColumnName("opis");
            entity.Property(e => e.ZdjecieZawodnikow)
                .IsUnicode(false)
                .HasColumnName("zdjecie_zawodnikow");
        });

        modelBuilder.Entity<Gracze>(entity =>
        {
            entity.HasKey(e => e.Nick).HasName("gracze_pk");

            entity.ToTable("gracze");

            entity.Property(e => e.Nick)
                .HasMaxLength(20)
                .IsUnicode(false)
                .HasColumnName("nick");
            entity.Property(e => e.Dywizja)
                .HasMaxLength(15)
                .IsUnicode(false)
                .HasColumnName("dywizja");
            entity.Property(e => e.Poziom).HasColumnName("poziom");
            entity.Property(e => e.UlubionyBohater)
                .HasMaxLength(20)
                .IsUnicode(false)
                .HasColumnName("ulubiony_bohater");

            entity.HasOne(d => d.UlubionyBohaterNavigation).WithMany(p => p.Graczes)
                .HasForeignKey(d => d.UlubionyBohater)
                .OnDelete(DeleteBehavior.SetNull)
                .HasConstraintName("bohaterowienazwareg_fk");

            entity.HasMany(d => d.GryIdMeczus).WithMany(p => p.GraczeNicks)
                .UsingEntity<Dictionary<string, object>>(
                    "GraczeGry",
                    r => r.HasOne<Gry>().WithMany()
                        .HasForeignKey("gry_id_meczu")
                        .HasConstraintName("gragracz_fk"),
                    l => l.HasOne<Gracze>().WithMany()
                        .HasForeignKey("gracze_nick")
                        .HasConstraintName("gracznick_fk"),
                    j =>
                    {
                        j.HasKey("gracze_nick", "gry_id_meczu").HasName("gracze_gry_pk");
                        j.ToTable("gracze_gry");
                    });
        });

        modelBuilder.Entity<GraczeZawodowi>(entity =>
        {
            entity.HasKey(e => e.Nick).HasName("gracze_zawodowi_pk");

            entity.ToTable("gracze_zawodowi");

            entity.HasIndex(e => e.Nick, "gracze_zawodowi__idx");

            entity.Property(e => e.Nick)
                .HasMaxLength(20)
                .IsUnicode(false)
                .HasColumnName("nick");
            entity.Property(e => e.DataUrodzin)
                .HasPrecision(0)
                .HasColumnName("data_urodzin");
            entity.Property(e => e.IdDruzyny)
                .HasMaxLength(6)
                .IsUnicode(false)
                .HasColumnName("id_druzyny");
            entity.Property(e => e.ImieINazwisko)
                .HasMaxLength(50)
                .IsUnicode(false)
                .HasColumnName("imie_i_nazwisko");
            entity.Property(e => e.Kraj)
                .HasMaxLength(30)
                .IsUnicode(false)
                .HasColumnName("kraj");
            entity.Property(e => e.Rezydencja)
                .HasMaxLength(20)
                .IsUnicode(false)
                .HasColumnName("rezydencja");
            entity.Property(e => e.Rola)
                .HasMaxLength(9)
                .IsUnicode(false)
                .HasColumnName("rola");
            entity.Property(e => e.UlubionyBohater)
                .HasMaxLength(20)
                .IsUnicode(false)
                .HasColumnName("ulubiony_bohater");
            entity.Property(e => e.Zdjecie)
                .IsUnicode(false)
                .HasColumnName("zdjecie");

            entity.HasOne(d => d.IdDruzynyNavigation).WithMany(p => p.GraczeZawodowis)
                .HasForeignKey(d => d.IdDruzyny)
                .OnDelete(DeleteBehavior.SetNull)
                .HasConstraintName("druzynyidpro_fk");

            entity.HasOne(d => d.UlubionyBohaterNavigation).WithMany(p => p.GraczeZawodowis)
                .HasForeignKey(d => d.UlubionyBohater)
                .OnDelete(DeleteBehavior.SetNull)
                .HasConstraintName("bohaterowienazwapro_fk");

            entity.HasMany(d => d.GryIdMeczus).WithMany(p => p.GraczeZawodowiNicks)
                .UsingEntity<Dictionary<string, object>>(
                    "GraczezawodowiGry",
                    r => r.HasOne<Gry>().WithMany()
                        .HasForeignKey("gry_id_meczu")
                        .HasConstraintName("gragraczzawodowy_fk"),
                    l => l.HasOne<GraczeZawodowi>().WithMany()
                        .HasForeignKey("gracze_zawodowi_nick")
                        .HasConstraintName("graczzawodowynick_fk"),
                    j =>
                    {
                        j.HasKey("gracze_zawodowi_nick", "gry_id_meczu").HasName("graczezawodowi_gry_pk");
                        j.ToTable("graczezawodowi_gry");
                    });
        });

        modelBuilder.Entity<Gry>(entity =>
        {
            entity.HasKey(e => e.IdMeczu).HasName("PK__gry__22D74D8834C9B7E0");

            entity.ToTable("gry");

            entity.Property(e => e.IdMeczu).HasColumnName("id_meczu");
            entity.Property(e => e.Asysty).HasColumnName("asysty");
            entity.Property(e => e.BohaterowieNazwa)
                .HasMaxLength(20)
                .IsUnicode(false)
                .HasColumnName("bohaterowie_nazwa");
            entity.Property(e => e.CreepScore).HasColumnName("creep_score");
            entity.Property(e => e.CzasGry)
                .HasPrecision(0)
                .HasColumnName("czas_gry");
            entity.Property(e => e.Rezultat)
                .HasMaxLength(4)
                .IsUnicode(false)
                .HasColumnName("rezultat");
            entity.Property(e => e.Smierci).HasColumnName("smierci");
            entity.Property(e => e.Strona)
                .HasMaxLength(4)
                .IsUnicode(false)
                .HasColumnName("strona");
            entity.Property(e => e.Zabojstwa).HasColumnName("zabojstwa");
            entity.Property(e => e.ZabojstwaDruzyny).HasColumnName("zabojstwa_druzyny");
            entity.Property(e => e.ZadaneObrazenia).HasColumnName("zadane_obrazenia");
            entity.Property(e => e.ZdobyteZloto).HasColumnName("zdobyte_zloto");
            entity.Property(e => e.ZgonyDruzyny).HasColumnName("zgony_druzyny");

            entity.HasOne(d => d.BohaterowieNazwaNavigation).WithMany(p => p.Gries)
                .HasForeignKey(d => d.BohaterowieNazwa)
                .OnDelete(DeleteBehavior.SetNull)
                .HasConstraintName("gry_bohaterowie_fk");
        });

        modelBuilder.Entity<GryZakupioneprzedmioty>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PK__gry_zaku__3213E83F9FB38B43");

            entity.ToTable("gry_zakupioneprzedmioty");

            entity.Property(e => e.Id).HasColumnName("id");
            entity.Property(e => e.IdMeczu).HasColumnName("id_meczu");
            entity.Property(e => e.IdZakupionegoPrzedmiotu).HasColumnName("id_zakupionego_przedmiotu");

            entity.HasOne(d => d.IdMeczuNavigation).WithMany(p => p.GryZakupioneprzedmioties)
                .HasForeignKey(d => d.IdMeczu)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("graidmeczu_fk");

            entity.HasOne(d => d.IdZakupionegoPrzedmiotuNavigation).WithMany(p => p.GryZakupioneprzedmioties)
                .HasForeignKey(d => d.IdZakupionegoPrzedmiotu)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("przedmiotid3_fk");
        });

        modelBuilder.Entity<KomponentyPrzedmiotow>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PK__komponen__3213E83FF4A2A102");

            entity.ToTable("komponenty_przedmiotow");

            entity.HasIndex(e => new { e.IdPrzed, e.IdKomponentu }, "komponenty_przedmiotow__idx");

            entity.Property(e => e.Id).HasColumnName("id");
            entity.Property(e => e.IdKomponentu).HasColumnName("id_komponentu");
            entity.Property(e => e.IdPrzed).HasColumnName("id_przed");

            entity.HasOne(d => d.IdKomponentuNavigation).WithMany(p => p.KomponentyPrzedmiotowIdKomponentuNavigations)
                .HasForeignKey(d => d.IdKomponentu)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("przedmiotyid2_fk");

            entity.HasOne(d => d.IdPrzedNavigation).WithMany(p => p.KomponentyPrzedmiotowIdPrzedNavigations)
                .HasForeignKey(d => d.IdPrzed)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("przedmiotyid1_fk");
        });

        modelBuilder.Entity<Przedmioty>(entity =>
        {
            entity.HasKey(e => e.IdPrzed).HasName("przedmioty_pk");

            entity.ToTable("przedmioty");

            entity.HasIndex(e => e.IdPrzed, "przedmioty__idx");

            entity.Property(e => e.IdPrzed)
                .ValueGeneratedNever()
                .HasColumnName("id_przed");
            entity.Property(e => e.Cena).HasColumnName("cena");
            entity.Property(e => e.Ikona)
                .IsUnicode(false)
                .HasColumnName("ikona");
            entity.Property(e => e.Nazwa)
                .HasMaxLength(100)
                .IsUnicode(false)
                .IsFixedLength()
                .HasColumnName("nazwa");
            entity.Property(e => e.Statystyki)
                .IsUnicode(false)
                .HasColumnName("statystyki");
            entity.Property(e => e.WartoscSprzedazy).HasColumnName("wartosc_sprzedazy");
        });

        modelBuilder.Entity<Turnieje>(entity =>
        {
            entity.HasKey(e => new { e.NazwaTurnieju, e.IdDruzyny }).HasName("turnieje_pk");

            entity.ToTable("turnieje");

            entity.Property(e => e.NazwaTurnieju)
                .HasMaxLength(70)
                .IsUnicode(false)
                .HasColumnName("nazwa_turnieju");
            entity.Property(e => e.IdDruzyny)
                .HasMaxLength(6)
                .IsUnicode(false)
                .HasColumnName("id_druzyny");
            entity.Property(e => e.Data)
                .HasPrecision(0)
                .HasColumnName("data");
            entity.Property(e => e.Nagroda)
                .HasColumnType("decimal(10, 5)")
                .HasColumnName("nagroda");
            entity.Property(e => e.OstatniWynik)
                .HasMaxLength(10)
                .IsUnicode(false)
                .HasColumnName("ostatni_wynik");
            entity.Property(e => e.Rodzaj)
                .HasMaxLength(8)
                .IsUnicode(false)
                .HasColumnName("rodzaj");
            entity.Property(e => e.ZajeteMiejsce).HasColumnName("zajete_miejsce");

            entity.HasOne(d => d.IdDruzynyNavigation).WithMany(p => p.Turniejes)
                .HasForeignKey(d => d.IdDruzyny)
                .HasConstraintName("druzynyidtur_fk");
        });

        OnModelCreatingPartial(modelBuilder);
    }

    partial void OnModelCreatingPartial(ModelBuilder modelBuilder);
}
