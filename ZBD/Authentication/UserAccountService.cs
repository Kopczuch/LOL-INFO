using Microsoft.Data.SqlClient;
using System.Collections.Generic;

namespace ZBD.Authentication
{
	public class UserAccountService
	{
        private List<UserAccount> _userAccountList;

        public UserAccountService()
        {
            // Connect to the database
            using (var connection = new SqlConnection("Data Source=PC\\SQLEXPRESS;Integrated Security=True;Connect Timeout=30;Encrypt=False;TrustServerCertificate=False;ApplicationIntent=ReadWrite;MultiSubnetFailover=False"))
            {
                connection.Open();

                // Retrieve data from the data_loggin table
                using (var command = new SqlCommand("SELECT * FROM dane_logowania", connection))
                {
                    using (var reader = command.ExecuteReader())
                    {
                        _userAccountList = new List<UserAccount>();
                        while (reader.Read())
                        {
                            _userAccountList.Add(new UserAccount
                            {
                                UserName = reader["nick"].ToString(),
                                Password = reader["haslo"].ToString(),
                                Role = reader["rola"].ToString()
                            });
                            Console.WriteLine(_userAccountList.Count);
                        }
                    }
                }
            }
        }

        public UserAccount? GetUserAccountByUserName(string userName)
        {
            return _userAccountList.FirstOrDefault(x => x.UserName == userName);
        }
    }
}
