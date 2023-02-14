using ZBD.Models;

namespace ZBD.Services
{
	public interface IPrzedmiotyService
	{
        public string AddUpdate(Przedmioty item);
        public bool Delete(int id);
        public Przedmioty GetById(int id);
        public List<Przedmioty> GetAll(); 
    }
}