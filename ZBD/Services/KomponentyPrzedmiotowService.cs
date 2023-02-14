using Microsoft.Data.SqlClient;
using ZBD.Models;

namespace ZBD.Services
{
	public class KomponentyPrzedmiotowService : IKomponentyPrzedmiotowService
    {
		private readonly LolInfoContext _ctx;
        ConnectionString conn = new();

		public KomponentyPrzedmiotowService(LolInfoContext ctx)
		{
			_ctx = ctx;
		}

        public string Add(KomponentyPrzedmiotow component)
        {
            try
            {
                _ctx.KomponentyPrzedmiotows.Add(component);
                _ctx.SaveChanges();
                return "ok";
            }
            catch (Exception ex)
            {
                return ex.Message;
            }
        }
        
        public string UpdateRow(long id, int idKomponentu)
        {
            var connection = new SqlConnection(conn.ConnString);
            SqlCommand cmd = new SqlCommand(
                "UPDATE dbo.komponenty_przedmiotow SET id_komponentu = @idKomponentu WHERE id=@id", connection);
            cmd.Parameters.AddWithValue("@idKomponentu", idKomponentu);
            cmd.Parameters.AddWithValue("@id", id);
            try
            {
                connection.Open();
                cmd.ExecuteNonQuery();
                connection.Close();
                return "ok";
            }
            catch (Exception ex)
            {
                return ex.Message;
            }
        }

        public bool Delete(int id)
        {
            try
            {
                var component = GetById(id);
                if (component == null)
                    return false;
                _ctx.KomponentyPrzedmiotows.Remove(component);
                _ctx.SaveChanges();
                return true;
            }
            catch (Exception ex)
            {
                return false;
            }
        }

        public KomponentyPrzedmiotow GetById(int id)
		{
			return _ctx.KomponentyPrzedmiotows.FirstOrDefault(i => i.Id == id);
		}

		public List<KomponentyPrzedmiotow> GetAll()
		{
			return _ctx.KomponentyPrzedmiotows
				.OrderBy(i => i.Id)
				.ToList();
		}
    }
}
