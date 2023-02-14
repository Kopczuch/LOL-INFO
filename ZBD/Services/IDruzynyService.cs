using ZBD.Models;

namespace ZBD.Services
{
    public interface IDruzynyService
    {
        public string AddUpdate(Druzyny team, string id);
        public bool Delete(string id);
        public Druzyny GetById(string id);
        public List<Druzyny> GetAll();
        public List<GraczeZawodowi> GetMembers(string id);
    }
}