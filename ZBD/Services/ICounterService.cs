using ZBD.Models;

namespace ZBD.Services
{
    public interface ICounterService
    {
        public List<Counter> GetAll();
        public bool EditCounter(string bohater, string kontra, string nowaKontra);
    }
}