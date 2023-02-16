using ZBD.Models;

namespace ZBD.Services
{
    public interface IGryService
    {
        public string AddUpdate(Gry game, char pro, string nick);
        public Gry GetById(long id);
        public List<Gry> GetAll();
        public bool Delete(long id);
    }
}