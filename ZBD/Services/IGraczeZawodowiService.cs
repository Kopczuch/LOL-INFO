using ZBD.Models;

namespace ZBD.Services
{
	public interface IGraczeZawodowiService
	{
        public string AddUpdate(GraczeZawodowi pro);
        public bool Delete(string nick);
        public GraczeZawodowi GetByNick(string nick);
        public List<GraczeZawodowi> GetAll();
        public string GetWr(string nick, char pro);
        public string GetAvgKda(string nick, char pro);
    }
}