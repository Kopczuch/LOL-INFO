using ZBD.Models;

namespace ZBD.Services
{
    public interface IBohaterowieService
    {
        string AddUpdate(Bohaterowie champion, string refName);

        bool Delete(string name);

        Bohaterowie GetByName(string name);

        List<Bohaterowie> GetAll();
    }
}
