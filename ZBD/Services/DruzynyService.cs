using Microsoft.EntityFrameworkCore;
using ZBD.Models;

namespace ZBD.Services
{
    public class DruzynyService : IDruzynyService
    {
        private readonly LolInfoContext _ctx;

        public DruzynyService(LolInfoContext ctx)
        {
            _ctx = ctx;
        }

        public string AddUpdate(Druzyny team, string id)
        {
            string res = string.Empty;
            try
            {
                if (id == null)
                {
                    _ctx.Druzynies.Add(team);
                    res = "okAdd";
                }
                else
                {
                    _ctx.Druzynies.Update(team);
                    res = "okUpdate";
                }
                _ctx.SaveChanges();
                return res;
            }
            catch (Exception ex)
            {
                if (ex.Message == "The instance of entity type 'Druzyny' cannot be tracked because another instance with the same key value for {'IdDruzyny'} is already being tracked. When attaching existing entities, ensure that only one entity instance with a given key value is attached. Consider using 'DbContextOptionsBuilder.EnableSensitiveDataLogging' to see the conflicting key values.")
                    return "Podane ID drużyny jest już zajęte.";
                else
                    return ex.Message;
            }
        }

        public bool Delete(string id)
        {
            try
            {
                var team = GetById(id);
                if (team == null)
                    return false;
                _ctx.Druzynies.Remove(team);
                _ctx.SaveChanges();
                return true;
            }
            catch (Exception ex)
            {
                return false;
            }
        }

        public Druzyny GetById(string id)
        {
            return _ctx.Druzynies
                .Include(t => t.Turniejes)
                .FirstOrDefault(t => t.IdDruzyny == id);
        }

        public List<Druzyny> GetAll()
        {
            return _ctx.Druzynies
                .Include(t => t.Turniejes)
                .ToList();
        }

        public List<GraczeZawodowi> GetMembers(string id)
        {
            return _ctx.GraczeZawodowis.FromSqlRaw($"EXEC dbo.znajdz_graczy_druzyny @p_team_id = {id}").ToList();
        }
    }
}
