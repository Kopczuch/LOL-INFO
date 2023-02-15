using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using ZBD.Models;

namespace ZBD.Services
{
	public class GraczeZawodowiService : IGraczeZawodowiService
	{
		private readonly LolInfoContext _ctx;
        private readonly IConfiguration _config;

        public GraczeZawodowiService(LolInfoContext ctx, IConfiguration configuration)
		{
			_ctx = ctx;
            _config = configuration;
		}

        public string AddUpdate(GraczeZawodowi pro)
        {
            string res = string.Empty;
            try
            {
                if (GetByNick(pro.Nick) == null)
                {
                    _ctx.GraczeZawodowis.Add(pro);
                    res = "okAdd";
                }
                else
                {
                    _ctx.GraczeZawodowis.Update(pro);
                    res = "okUpdate";
                }
                _ctx.SaveChanges();
                return res;
            }
            catch (Exception ex)
            {
                if (ex.Message == "The instance of entity type 'GraczeZawodowi' cannot be tracked because another instance with the same key value for {'Nick'} is already being tracked. When attaching existing entities, ensure that only one entity instance with a given key value is attached. Consider using 'DbContextOptionsBuilder.EnableSensitiveDataLogging' to see the conflicting key values.")
                    return "Podana nazwa bohatera jest już zajęta.";
                else
                    return ex.Message;
            }
        }

        public bool Delete(string nick)
        {
            try
            {
                var pro = GetByNick(nick);
                if (pro == null)
                    return false;
                _ctx.GraczeZawodowis.Remove(pro);
                _ctx.SaveChanges();
                return true;
            }
            catch (Exception ex)
            {
                return false;
            }
        }

        public GraczeZawodowi GetByNick(string nick)
        {
            return _ctx.GraczeZawodowis
                .Include(p => p.GryIdMeczus)
                .FirstOrDefault(p => p.Nick == nick);
        }

        public List<GraczeZawodowi> GetAll()
        {
            return _ctx.GraczeZawodowis.ToList();
        }

        public string GetWr(string nick, char pro)
        {
            var connection = new SqlConnection(_config.GetConnectionString("Default"));
            SqlCommand cmd = new SqlCommand("select dbo.win_rate(@pNick, @pro)", connection);
            cmd.Parameters.AddWithValue("@pNick", nick);
            cmd.Parameters.AddWithValue("@pro", pro);
            connection.Open();
            string wr = cmd.ExecuteScalar().ToString();
            connection.Close();
            return wr;
        }

        public string GetAvgKda(string nick, char pro)
        {
            var connection = new SqlConnection(_config.GetConnectionString("Default"));
            SqlCommand cmd = new SqlCommand("select dbo.srednie_KDA(@pNick, @pro)", connection);
            cmd.Parameters.AddWithValue("@pNick", nick);
            cmd.Parameters.AddWithValue("@pro", pro);
            connection.Open();
            string avgKda = cmd.ExecuteScalar().ToString();
            connection.Close();
            return avgKda;
        }
    }
}
