using Microsoft.EntityFrameworkCore;
using ZBD.Models;

namespace ZBD.Services
{
    public class DruzynyService : IDruzynyService
    {
        private readonly MasterContext _ctx;

        public DruzynyService(MasterContext ctx)
        {
            _ctx = ctx;
        }

        public Druzyny GetById(string id)
        {
            return _ctx.Druzynies.FirstOrDefault(t => t.IdDruzyny == id);
        }

        public List<Druzyny> GetAll()
        {
            return _ctx.Druzynies.ToList();
        }

        public List<GraczeZawodowi> GetMembers(string id)
        {
            return _ctx.GraczeZawodowis.FromSqlRaw($"EXEC dbo.znajdz_graczy_druzyny @p_team_id = {id}").ToList();
        }
    }
}
