using Microsoft.EntityFrameworkCore;
using ZBD.Models;

namespace ZBD.Services
{
	public class GryService : IGryService
	{
		private readonly MasterContext _ctx;

		public GryService(MasterContext ctx)
		{
			_ctx = ctx;
		}

		public bool AddUpdate(Gry game)
		{
			try
			{
				if (game.IdMeczu == 0)
					_ctx.Add(game);
				else
					_ctx.Update(game);
				_ctx.SaveChanges();
				return true;
			}
			catch(Exception ex)
			{
				return false;
			}
		}

		public Gry GetById(long id)
		{
			return _ctx.Gries
				.Include(g => g.GraczeNicks)
				.Include(p => p.GraczeZawodowiNicks)
				//.Include(i => i.IdZakupionegoPrzedmiotus)
				.FirstOrDefault(i => i.IdMeczu == id);
		}

		public List<Gry> GetAll()
		{
			return _ctx.Gries
				.Include(g => g.GraczeNicks)
				.Include(p => p.GraczeZawodowiNicks)
				//.Include(i => i.IdZakupionegoPrzedmiotus)
				.ToList();

        }

		public bool Update(Gracze player)
		{
			throw new NotImplementedException();
		}

		public Gracze GetByNick(string nick)
		{
			throw new NotImplementedException();
		}
	}
}
