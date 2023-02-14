using ZBD.Models;

namespace ZBD.Services
{
    public interface ICounterService
    {
        public List<Counter> GetAll();
        public bool EditCounter(string bohater, string kontra, string nowaKontra);
        public bool AddCounter(string bohater, string kontra);
        public bool Delete(string bohater, string kontra);
    }
}