using Microsoft.Data.SqlClient;
using ZBD.Models;
using Microsoft.Extensions.Configuration;

namespace ZBD.Services
{
    public class ComponentService : IComponentService
    {
        private readonly IConfiguration _config;

        public ComponentService(IConfiguration configuration)
        {
            _config = configuration;
        }

        public List<Component> GetComponents(int id)
        {
            var connection = new SqlConnection(_config.GetConnectionString("Default"));
            SqlCommand cmd = new SqlCommand("EXEC znajdz_komponenty @id;", connection);
            cmd.Parameters.AddWithValue("@id", id);
            connection.Open();
            SqlDataReader rdr = cmd.ExecuteReader();

            List<Component> components = new List<Component>();

            while (rdr.Read())
            {
                components.Add(new Component
                {
                    id = int.Parse(rdr["id"].ToString()),
                    id_przed = int.Parse(rdr["id_przed"].ToString()),
                    nazwa = rdr["nazwa"].ToString(),
                    Level = int.Parse(rdr["Level"].ToString())
                });
            }

            connection.Close();
            return components;
        }
    }
}
