using ZBD.Models;

namespace ZBD.Services
{
	public interface IKomponentyPrzedmiotowService
	{
        public KomponentyPrzedmiotow GetById(int id);
        public List<KomponentyPrzedmiotow> GetAll();
        public string Add(KomponentyPrzedmiotow component);
        public string UpdateRow(long id, int idKomponentu);
        public bool Delete(int id);
    }
}