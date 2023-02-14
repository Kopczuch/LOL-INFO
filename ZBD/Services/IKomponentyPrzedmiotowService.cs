using ZBD.Models;

namespace ZBD.Services
{
	public interface IKomponentyPrzedmiotowService
	{
        public KomponentyPrzedmiotow GetById(int id);
        public List<KomponentyPrzedmiotow> GetAll();
        public string AddUpdate(KomponentyPrzedmiotow component);
    }
}