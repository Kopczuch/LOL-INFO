using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using ZBD.Models;

namespace ZBD.Services
{
    public class RegisterService: IRegisterService
    {
        private readonly LolInfoContext _ctx;
        private readonly IConfiguration _config;

        public RegisterService(LolInfoContext ctx, IConfiguration configuration)
        {
            _ctx = ctx;
            _config = configuration;
        }

        public string RegisterUser(RegisterDetails details)
        {
            string res = string.Empty;
            try
            {
                var connection = new SqlConnection(_config.GetConnectionString("Default"));
                SqlCommand cmd = new SqlCommand("EXEC register @nick, @haslo, @dywizja, @poziom, @ulubiony_bohater;", connection);
                cmd.Parameters.AddWithValue("@nick", details.UserName);
                cmd.Parameters.AddWithValue("@haslo", details.Password);
                cmd.Parameters.AddWithValue("@dywizja", details.Dywizja);
                cmd.Parameters.AddWithValue("@poziom", details.Poziom);
                cmd.Parameters.AddWithValue("@ulubiony_bohater", details.UlubionyBohater != null ? details.UlubionyBohater : DBNull.Value);
                connection.Open();
                SqlDataReader rdr = cmd.ExecuteReader();
                connection.Close();
                res = "okAdd";
                _ctx.SaveChanges();
                return res;
            }
            catch (Exception ex)
            {
                return ex.Message;
            }
        }
    }
}
