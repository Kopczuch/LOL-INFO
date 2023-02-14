using ZBD.Models;

namespace ZBD.Services
{
    public interface IDruzynyService
    {
        public Druzyny GetById(string id);
        public List<Druzyny> GetAll();
        public List<GraczeZawodowi> GetMembers(string id);
    }
}