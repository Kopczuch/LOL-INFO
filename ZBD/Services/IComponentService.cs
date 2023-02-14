using ZBD.Models;

namespace ZBD.Services
{
	public interface IComponentService
	{
        public List<Component> GetComponents(int id);
    }
}