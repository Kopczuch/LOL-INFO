using Microsoft.Data.SqlClient;
using ZBD.Models;

namespace ZBD.Services
{
    public class ComponentService : IComponentService
    {
        ConnectionString conn = new();
        public List<Component> GetComponents(int id)
        {
            var connection = new SqlConnection(conn.ConnString);
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
