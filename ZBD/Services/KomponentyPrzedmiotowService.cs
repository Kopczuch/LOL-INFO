using ZBD.Models;

namespace ZBD.Services
{
	public class KomponentyPrzedmiotowService : IKomponentyPrzedmiotowService
    {
		private readonly MasterContext _ctx;

		public KomponentyPrzedmiotowService(MasterContext ctx)
		{
			_ctx = ctx;
		}

        public string AddUpdate(KomponentyPrzedmiotow component)
        {
            ///try
            ///{
                if (GetById(component.IdPrzed) == null)
                    _ctx.KomponentyPrzedmiotows.Add(component);
                else
                    _ctx.KomponentyPrzedmiotows.Update(component);
                _ctx.SaveChanges();
                return "ok";
            //}
            //catch (Exception ex)
            //{
            //    return ex.Message;
            //}
        }

        public KomponentyPrzedmiotow GetById(int id)
		{
			return _ctx.KomponentyPrzedmiotows.FirstOrDefault(i => i.Id == id);
		}

		public List<KomponentyPrzedmiotow> GetAll()
		{
			return _ctx.KomponentyPrzedmiotows
				.OrderBy(i => i.Id)
				.ToList();
		}
	}
}
