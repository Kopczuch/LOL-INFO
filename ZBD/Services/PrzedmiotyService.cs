using Microsoft.EntityFrameworkCore;
using ZBD.Models;

namespace ZBD.Services
{
	public class PrzedmiotyService : IPrzedmiotyService
	{
		private readonly LolInfoContext _ctx;

		public PrzedmiotyService(LolInfoContext ctx)
		{
			_ctx = ctx;
		}

		public string AddUpdate(Przedmioty item)
		{
			string res = string.Empty;
			try
			{
                if (GetById(item.IdPrzed) == null)
				{
                    _ctx.Przedmioties.Add(item);
					res = "okAdd";
                }
                else
				{
                    _ctx.Przedmioties.Update(item);
					res = "okUpdate";
                }
                _ctx.SaveChanges();
				return res;
            }
			catch(Exception ex)
			{
				return ex.Message;
			}
		}

		public bool Delete(int id)
		{
			try
			{
				var item = GetById(id);
				if (item == null)
					return false;
				_ctx.Przedmioties.Remove(item);
				_ctx.SaveChanges();
				return true;
			}
			catch(Exception ex)
			{
				return false;
			}
		}

		public Przedmioty GetById(int id)
		{
			return _ctx.Przedmioties.FirstOrDefault(i => i.IdPrzed == id);
		}

		public List<Przedmioty> GetAll()
		{
			return _ctx.Przedmioties.ToList();
		}

		public List<Przedmioty> GetAllAlfabetical()
		{
			return _ctx.Przedmioties
				.OrderBy(p => p.Nazwa)
				.ToList();
		}

    }
}
