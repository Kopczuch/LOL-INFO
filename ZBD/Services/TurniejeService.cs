using Microsoft.EntityFrameworkCore;
using ZBD.Models;

namespace ZBD.Services
{
    public class TurniejeService : ITurniejeService
    {
        private readonly LolInfoContext _ctx;

        public TurniejeService(LolInfoContext ctx)
        {
            _ctx = ctx;
        }

        public string AddUpdate(Turnieje tournament, string name)
        {
            string res = string.Empty;
            try
            {
                if (name == null)
                {
                    _ctx.Turniejes.Add(tournament);
                    res = "okAdd";
                }
                else
                {
                    _ctx.Turniejes.Update(tournament);
                    res = "okUpdate";
                }
                _ctx.SaveChanges();
                return res;
            }
            catch (Exception ex)
            {
                //if (ex.Message == "The instance of entity type 'Turnieje' cannot be tracked because another instance with the same key value for {'NazwaTurnieju'} is already being tracked. When attaching existing entities, ensure that only one entity instance with a given key value is attached. Consider using 'DbContextOptionsBuilder.EnableSensitiveDataLogging' to see the conflicting key values.")
                //    return "Podana nazwa turnieju jest już zajęta.";
                //else
                return ex.Message;
            }
        }

        public bool Delete(string name)
        {
            try
            {
                var tournament = GetByName(name);
                if (tournament == null)
                    return false;
                _ctx.Turniejes.Remove(tournament);
                _ctx.SaveChanges();
                return true;
            }
            catch (Exception ex)
            {
                return false;
            }
        }

        public Turnieje GetByName(string name)
        {
            return _ctx.Turniejes.FirstOrDefault(t => t.NazwaTurnieju == name);
        }

        public List<Turnieje> GetAll()
        {
            return _ctx.Turniejes.ToList();
        }
    }
}
