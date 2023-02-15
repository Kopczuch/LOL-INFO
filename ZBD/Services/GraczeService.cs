using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using ZBD.Models;

namespace ZBD.Services
{
    public class GraczeService : IGraczeService
    {
        private readonly LolInfoContext _ctx;
        private readonly IConfiguration _config;

        public GraczeService(LolInfoContext ctx, IConfiguration configuration)
        {
            _ctx = ctx;
            _config = configuration;
        }

        public bool Update(Gracze player)
        {
            try
            {
                _ctx.Graczes.Update(player);
                _ctx.SaveChanges();
                return true;
            }
            catch (Exception ex)
            {
                return false;
            }
        }

        public Gracze GetByNick(string nick)
        {
            return _ctx.Graczes
                .Include(g => g.GryIdMeczus)
                .FirstOrDefault(n => n.Nick == nick);

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
