using Microsoft.EntityFrameworkCore;
using ZBD.Models;

namespace ZBD.Services
{
    public class BohaterowieService : IBohaterowieService
    {
        private readonly MasterContext _ctx;

        public BohaterowieService(MasterContext ctx)
        {
            _ctx = ctx;
        }

        public string AddUpdate(Bohaterowie champion, string refName)
        {
            try
            {
            if (refName == null)
                _ctx.Bohaterowies.Add(champion);
            else
                _ctx.Bohaterowies.Update(champion);

            _ctx.SaveChanges();

            return "ok";
            }
            catch(Exception ex)
            {
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
