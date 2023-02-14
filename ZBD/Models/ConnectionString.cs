namespace ZBD.Models
{
    public class ConnectionString
    {
        public string ConnString { get; set; }

        public ConnectionString()
        {
            ConnString = "Data Source=PC\\SQLEXPRESS;Database=lolinfo;Integrated Security=True;Connect Timeout=30;Encrypt=False;TrustServerCertificate=False;ApplicationIntent=ReadWrite;MultiSubnetFailover=False";
        }
    }
}
