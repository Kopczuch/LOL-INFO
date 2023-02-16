using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using ZBD.Models;

namespace ZBD.Services
{
	public class GryService : IGryService
	{
		private readonly LolInfoContext _ctx;
		private readonly IConfiguration _config;

		public GryService(LolInfoContext ctx, IConfiguration configuration)
		{
			_ctx = ctx;
			_config = configuration;
		}

		public string AddUpdate(Gry game, char pro, string nick)
		{
			string res = string.Empty;
			try
			{
				if (GetById(game.IdMeczu) != null)
				{
                    _ctx.Update(game);
					res = "okUpdate";
                }	
				else
				{
                    var connection = new SqlConnection(_config.GetConnectionString("Default"));
                    SqlCommand cmd = new SqlCommand("EXEC wstaw_gre @nick, @proBool, @result, @kills, @deaths, @ass, @cs, @gold, @time, @dmg, @side, @kDr, @dDr, @champ;", connection);
                    cmd.Parameters.AddWithValue("@nick", nick);
                    cmd.Parameters.AddWithValue("@proBool", pro);
                    cmd.Parameters.AddWithValue("@result", game.Rezultat);
                    cmd.Parameters.AddWithValue("@kills", game.Zabojstwa);
                    cmd.Parameters.AddWithValue("@deaths", game.Smierci);
                    cmd.Parameters.AddWithValue("@ass", game.Asysty);
                    cmd.Parameters.AddWithValue("@cs", game.CreepScore);
                    cmd.Parameters.AddWithValue("@gold", game.ZdobyteZloto);
                    cmd.Parameters.AddWithValue("@time", game.CzasGry);
                    cmd.Parameters.AddWithValue("@dmg", game.ZadaneObrazenia);
                    cmd.Parameters.AddWithValue("@side", game.Strona);
					cmd.Parameters.AddWithValue("@kDr", game.ZabojstwaDruzyny != null ? game.ZabojstwaDruzyny : DBNull.Value);
                    cmd.Parameters.AddWithValue("@dDr", game.ZgonyDruzyny != null ? game.ZgonyDruzyny : DBNull.Value);
                    cmd.Parameters.AddWithValue("@champ", game.BohaterowieNazwa);
                    connection.Open();
                    SqlDataReader rdr = cmd.ExecuteReader();
                    connection.Close();

                    res = "okAdd";
				}
				_ctx.SaveChanges();
				return res;
			}
			catch(Exception ex)
			{
				return ex.Message;
			}
		}

        public bool Delete(long id)
        {
            try
            {
                var game = GetById(id);
                if (game == null)
                    return false;
                _ctx.Gries.Remove(game);
                _ctx.SaveChanges();
                return true;
            }
            catch (Exception ex)
            {
                return false;
            }
        }

        public Gry GetById(long id)
		{
			return _ctx.Gries
				.Include(g => g.GraczeNicks)
				.Include(p => p.GraczeZawodowiNicks)
				//.Include(i => i.IdZakupionegoPrzedmiotus)
				.FirstOrDefault(i => i.IdMeczu == id);
		}

		public List<Gry> GetAll()
		{
			return _ctx.Gries
				.Include(g => g.GraczeNicks)
				.Include(p => p.GraczeZawodowiNicks)
				//.Include(i => i.IdZakupionegoPrzedmiotus)
				.ToList();

        }
    }
}
