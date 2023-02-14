using ZBD.Models;

namespace ZBD.Services
{
    public interface ITurniejeService
    {
        public string AddUpdate(Turnieje tournament, string id);
        public bool Delete(string name);
        public Turnieje GetByName(string name);
        public List<Turnieje> GetAll();
    }
}