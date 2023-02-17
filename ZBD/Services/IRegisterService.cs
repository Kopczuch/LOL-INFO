using ZBD.Models;

namespace ZBD.Services
{
    public interface IRegisterService
    {
        public string RegisterUser(RegisterDetails details);
    }
}
