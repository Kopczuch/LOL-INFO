using Microsoft.EntityFrameworkCore;
using ZBD.Models;

namespace ZBD.Services
{
    public class DaneLogowaniaService: IDaneLogowaniaService
    {
        private readonly LolInfoContext _ctx;

        public DaneLogowaniaService(LolInfoContext ctx)
        {
            _ctx = ctx;
        }

        public DaneLogowania? GetUserByName(string userName) 
        {
            return _ctx.DaneLogowania.FirstOrDefault(n => n.Nick == userName);
        }

        public string AddUser(DaneLogowania user)
        {
            string res = string.Empty;
            try
            {
                _ctx.DaneLogowania.Add(user);
                res = "okAdd";
                _ctx.SaveChanges();
                return res;
            }
            catch (Exception ex)
            {
                 return "Błąd przy dodawaniu użytkownika";
            }

        }
    }
}
