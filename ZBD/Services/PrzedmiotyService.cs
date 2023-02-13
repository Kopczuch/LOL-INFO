using Microsoft.EntityFrameworkCore;
using ZBD.Models;

namespace ZBD.Services
{
	public class PrzedmiotyService : IPrzedmiotyService
	{
		private readonly MasterContext _ctx;

		public PrzedmiotyService(MasterContext ctx)
		{
			_ctx = ctx;
		}

		public string AddUpdate(Przedmioty item)
		{
			try
			{
                if (GetById(item.IdPrzed) == null)
                    _ctx.Przedmioties.Add(item);
                else
                    _ctx.Przedmioties.Update(item);
				_ctx.SaveChanges();
				return "ok";
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
	}
}
