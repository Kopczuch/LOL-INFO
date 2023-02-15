using Microsoft.Data.SqlClient;
using ZBD.Models;
using Microsoft.Extensions.Configuration;

namespace ZBD.Services
{
    public class CounterService : ICounterService
    {
        private readonly IConfiguration _config;

        public CounterService(IConfiguration configuration)
        {
            _config = configuration;
        }

        public List<Counter> GetAll()
        {
            var connection = new SqlConnection(_config.GetConnectionString("Default"));
            SqlCommand cmd = new SqlCommand("select * from dbo.kontry;", connection);
            connection.Open();
            SqlDataReader rdr = cmd.ExecuteReader();

            List<Counter> counters = new List<Counter>();

            while (rdr.Read())
            {
                counters.Add(new Counter
                {
                    bohater = rdr["bohater"].ToString(),
                    kontra = rdr["kontra"].ToString()
                });
            }

            connection.Close();
            return counters;
        }

        public bool EditCounter(string bohater, string kontra, string nowaKontra)
        {
            var connection = new SqlConnection(_config.GetConnectionString("Default"));
            SqlCommand cmd = new SqlCommand(
                "UPDATE dbo.kontry SET bohater = @bohater, kontra = @nowaKontra WHERE bohater = @bohater and kontra = @kontra;", connection);
            cmd.Parameters.AddWithValue("@bohater", bohater);
            cmd.Parameters.AddWithValue("@kontra", kontra);
            cmd.Parameters.AddWithValue("@nowaKontra", nowaKontra);
            try
            {
                connection.Open();
                cmd.ExecuteNonQuery();
                connection.Close();
                return true;
            }
            catch(Exception ex)
            {
                return false;
            }

        }

        public bool AddCounter(string bohater, string kontra)
        {
            var connection = new SqlConnection(_config.GetConnectionString("Default"));
            SqlCommand cmd = new SqlCommand(
                "INSERT INTO dbo.kontry(bohater, kontra) VALUES(@bohater, @kontra)", connection);
            cmd.Parameters.AddWithValue("@bohater", bohater);
            cmd.Parameters.AddWithValue("@kontra", kontra);
            try
            {
                connection.Open();
                cmd.ExecuteNonQuery();
                connection.Close();
                return true;
            }
            catch (Exception ex)
            {
                return false;
            }
        }

        public bool Delete(string bohater, string kontra)
        {
            var connection = new SqlConnection(_config.GetConnectionString("Default"));
            SqlCommand cmd = new SqlCommand(
                "DELETE FROM dbo.kontry WHERE bohater = @bohater AND kontra = @kontra", connection);
            cmd.Parameters.AddWithValue("@bohater", bohater);
            cmd.Parameters.AddWithValue("@kontra", kontra);
            try
            {
                connection.Open();
                cmd.ExecuteNonQuery();
                connection.Close();
                return true;
            }
            catch (Exception ex)
            {
                return false;
            }
        }


    }
}
