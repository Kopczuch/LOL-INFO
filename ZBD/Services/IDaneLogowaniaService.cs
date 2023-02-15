using ZBD.Models;

namespace ZBD.Services
{
    public interface IDaneLogowaniaService
    {
        DaneLogowania? GetUserByName(string userName);

        string AddUser(DaneLogowania dane);
    }
}
