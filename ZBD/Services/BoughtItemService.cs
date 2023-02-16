using Microsoft.Data.SqlClient;
using ZBD.Models;
using Microsoft.Extensions.Configuration;

namespace ZBD.Services
{
    public class BoughtItemService : IBoughtItemService
    {
        private readonly IConfiguration _config;

        public BoughtItemService(IConfiguration configuration)
        {
            _config = configuration;
        }

        public List<BoughtItem> GetAll(long id)
        {
            var connection = new SqlConnection(_config.GetConnectionString("Default"));
            SqlCommand cmd = new SqlCommand("EXEC znajdz_zakupione_przedmioty @id;", connection);
            cmd.Parameters.AddWithValue("@id", id);
            connection.Open();
            SqlDataReader rdr = cmd.ExecuteReader();
            List<BoughtItem> boughtItems = new List<BoughtItem>();

            while (rdr.Read())
            {
                boughtItems.Add(new BoughtItem
                {
                    id_przed = int.Parse(rdr["id_przed"].ToString()),
                    nazwa = rdr["nazwa"].ToString(),
                    ikona = rdr["ikona"].ToString()
                });
            }

            connection.Close();
            return boughtItems;
        }

        public string Add(long gameId, int itemId)
        {
            var connection = new SqlConnection(_config.GetConnectionString("Default"));
            SqlCommand cmd = new SqlCommand("INSERT INTO dbo.gry_zakupioneprzedmioty VALUES(@gameId, @itemId);", connection);
            cmd.Parameters.AddWithValue("@gameId", gameId);
            cmd.Parameters.AddWithValue("@itemId", itemId);
            try
            {
                connection.Open();
                SqlDataReader rdr = cmd.ExecuteReader();
                List<BoughtItem> boughtItems = new List<BoughtItem>();
                connection.Close();
                return "okAdd";
            }
            catch (Exception ex)
            {
                return ex.Message;
            }
        }

        public string Update(long gameId, int itemId, int newItemId)
        {
            var connection = new SqlConnection(_config.GetConnectionString("Default"));
            SqlCommand cmd = new SqlCommand("UPDATE dbo.gry_zakupioneprzedmioty SET id_zakupionego_przedmiotu = @newItemId WHERE id = @gameId AND id_zakupionego_przedmiotu = @itemId;", connection);
            cmd.Parameters.AddWithValue("@gameId", gameId);
            cmd.Parameters.AddWithValue("@itemId", itemId);
            cmd.Parameters.AddWithValue("@newItemId", newItemId);
            try
            {
                connection.Open();
                SqlDataReader rdr = cmd.ExecuteReader();
                List<BoughtItem> boughtItems = new List<BoughtItem>();
                connection.Close();
                return "okUpdate";
            }
            catch (Exception ex)
            {
                return ex.Message;
            }
        }

        public string Delete(long gameId, int itemId)
        {
            var connection = new SqlConnection(_config.GetConnectionString("Default"));
            SqlCommand cmd = new SqlCommand("DELETE dbo.gry_zakupioneprzedmioty WHERE id = @gameId AND id_zakupionego_przedmiotu = @itemId;", connection);
            cmd.Parameters.AddWithValue("@gameId", gameId);
            cmd.Parameters.AddWithValue("@itemId", itemId);
            try
            {
                connection.Open();
                SqlDataReader rdr = cmd.ExecuteReader();
                List<BoughtItem> boughtItems = new List<BoughtItem>();
                connection.Close();
                return "ok";
            }
            catch (Exception ex)
            {
                return ex.Message;
            }
        }
    }
}
