using Microsoft.EntityFrameworkCore;
using ZBD.Models;

namespace ZBD.Services
{
    public class BohaterowieService : IBohaterowieService
    {
        private readonly LolInfoContext _ctx;

        public BohaterowieService(LolInfoContext ctx)
        {
            _ctx = ctx;
        }

        public string AddUpdate(Bohaterowie champion, string refName)
        {
            string res = string.Empty;
            try
            {
                if (refName == null)
                {
                    _ctx.Bohaterowies.Add(champion);
                    res = "okAdd";
                }
                    
                else
                {
                    _ctx.Bohaterowies.Update(champion);
                    res = "okUpdate";
                }
                _ctx.SaveChanges();
                return res;
            }
            catch (Exception ex)
            {
                if (ex.Message == "The instance of entity type 'Bohaterowie' cannot be tracked because another instance with the same key value for {'Nazwa'} is already being tracked. When attaching existing entities, ensure that only one entity instance with a given key value is attached. Consider using 'DbContextOptionsBuilder.EnableSensitiveDataLogging' to see the conflicting key values.")
                    return "Podana nazwa bohatera jest już zajęta.";
                else
                    return ex.Message;
            }
}

        public bool Delete(string name)
        {
            try
            {
                var champion = GetByName(name);
                if (champion == null)
                    return false;
                _ctx.Bohaterowies.Remove(champion);
                _ctx.SaveChanges();
                return true;
            }
            catch (Exception ex)
            {
                return false;
            }
        }

        public Bohaterowie GetByName(string name)
        {
            return _ctx.Bohaterowies
                .Include(k => k.Kontras)
                .FirstOrDefault(n => n.Nazwa == name);
        }

        public List<Bohaterowie> GetAll()
        {
            return _ctx.Bohaterowies
                .Include(k => k.Kontras)
                .ToList();
        }

    }
}
