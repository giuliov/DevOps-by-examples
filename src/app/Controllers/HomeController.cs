using app.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Configuration;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.Threading.Tasks;

// For more information on enabling MVC for empty projects, visit http://go.microsoft.com/fwlink/?LinkID=397860

namespace app.Controllers
{
    public class HomeController : Controller
    {
        private IConfiguration Configuration { get; set; }

        public HomeController(IConfiguration configuration)
        {
            Configuration = configuration;
        }

        // GET: /<controller>/
        public IActionResult Index()
        {
            return View();
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Index(string searchString)
        {
            var nations = new List<Nation>();

            string connectionString = Configuration.GetValue<string>("Data:ConnectionString");
            using (var conn = new SqlConnection(connectionString))
            {
                conn.Open();

                string sql = "SELECT Code,Name FROM ISO_3166_2 WHERE Name LIKE @searchString";
                using (var cmd = new SqlCommand(sql,conn))
                {
                    searchString = searchString ?? string.Empty;
                    cmd.Parameters.AddWithValue("searchString", searchString + "%");
                    using (var reader = await cmd.ExecuteReaderAsync())
                    {
                        while (await reader.ReadAsync())
                        {
                            nations.Add(new Nation { ISOCode = reader.GetString(0), EnglishName = reader.GetString(1) });
                        }
                    }
                }
            }

            return View(nations);
        }
    }
}
