using Microsoft.AspNetCore.Components;
using Microsoft.AspNetCore.Components.Web;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Scaffolding.Metadata;
using ZBD.Authentication;
using Microsoft.AspNetCore.ResponseCompression;
using System.Text;
using ZBD.Data;
using ZBD.Models;
using ZBD.Services;
using Blazored.SessionStorage;
using Microsoft.AspNetCore.Components.Authorization;
using ZBD;
using Microsoft.AspNetCore.Components.Server.ProtectedBrowserStorage;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddAuthenticationCore();
builder.Services.AddRazorPages();
builder.Services.AddServerSideBlazor();
builder.Services.AddScoped<ProtectedSessionStorage>();
builder.Services.AddScoped<AuthenticationStateProvider, CustomAuthenticationStateProvider>();

builder.Services.AddSingleton<WeatherForecastService>();

builder.Services.AddDbContext<LolInfoContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("conn")));

builder.Services.AddTransient<IDaneLogowaniaService, DaneLogowaniaService>();
builder.Services.AddTransient<IBohaterowieService, BohaterowieService>();
builder.Services.AddTransient<IGraczeService, GraczeService>();
builder.Services.AddTransient<IGryService, GryService>();
builder.Services.AddTransient<ICounterService, CounterService>();
builder.Services.AddTransient<IPrzedmiotyService, PrzedmiotyService>();
builder.Services.AddTransient<IComponentService, ComponentService>();
builder.Services.AddTransient<IKomponentyPrzedmiotowService, KomponentyPrzedmiotowService>();
builder.Services.AddTransient<IDruzynyService, DruzynyService>();
builder.Services.AddTransient<ITurniejeService, TurniejeService>();
builder.Services.AddTransient<IGraczeZawodowiService, GraczeZawodowiService>();
builder.Services.AddTransient<IBoughtItemService, BoughtItemService>();
builder.Services.AddTransient<IRegisterService, RegisterService>();

var app = builder.Build();


// Configure the HTTP request pipeline.
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Error");
    // The default HSTS value is 30 days. You may want to change this for production scenarios, see https://aka.ms/aspnetcore-hsts.
    app.UseHsts();
}

app.UseHttpsRedirection();

app.UseStaticFiles();

app.UseRouting();

app.MapBlazorHub();
app.MapFallbackToPage("/_Host");

app.Run();
