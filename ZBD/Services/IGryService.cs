using ZBD.Models;

namespace ZBD.Services
{
    public interface IGryService
    {
        public bool AddUpdate(Gry game);
        public Gry GetById(long id);
        public List<Gry> GetAll();
        public bool Update(Gracze player);
    }
}