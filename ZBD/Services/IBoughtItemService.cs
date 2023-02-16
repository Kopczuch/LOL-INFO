using ZBD.Models;

namespace ZBD.Services
{
    public interface IBoughtItemService
    {
        public List<BoughtItem> GetAll(long id);
        public string Add(long gameId, int itemId);
        public string Update(long gameId, int itemId, int newItemId);
        public string Delete(long gameId, int itemId);
    }
}