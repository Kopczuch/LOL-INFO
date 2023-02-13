using ZBD.Models;

namespace ZBD.Services
{
    public interface IGraczeService
    {
        public bool Update(Gracze player);
        public Gracze GetByNick(string nick);
        public string GetWr(string nick, char pro);
        public string GetAvgKda(string nick, char pro);
    }
}