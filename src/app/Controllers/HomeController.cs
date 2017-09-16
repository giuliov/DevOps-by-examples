using app.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Configuration;
using Microsoft.ApplicationInsights;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.Threading.Tasks;

// For more information on enabling MVC for empty projects, visit http://go.microsoft.com/fwlink/?LinkID=397860

namespace app.Controllers
{
    public class HomeController : Controller
    {
        private IConfiguration Configuration { get; set; }
        private TelemetryClient TelemetryClient { get; set; }

        public HomeController(IConfiguration configuration)
        {
            Configuration = configuration;
            TelemetryClient = new TelemetryClient();
        }

        private NationsViewModel MakeNationsViewModel()
        {
            string LaunchDarklyKey = Configuration.GetValue<string>("Data:LaunchDarklyKey", string.Empty);
            var ldClient = new LaunchDarkly.Client.LdClient(LaunchDarklyKey);
            var ldUser = LaunchDarkly.Client.User.WithKey("anonymous");

            return new NationsViewModel()
            {
                ShowTimeFeatureOn = Configuration.GetValue<bool>("Features:ShowTime", false),
                ExtendedCountriesDisplayFeatureOn = ldClient.BoolVariation("extended-countries-display", ldUser, false),
                Nations = null
            };
        }

        // GET: /<controller>/
        public IActionResult Index()
        {
            var vm = MakeNationsViewModel();
            return View(vm);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Index(string searchString)
        {
            var vm = MakeNationsViewModel();
            vm.Nations = new List<Nation>();

            TrackUserQuery(searchString);

            string connectionString = Configuration.GetValue<string>("Data:ConnectionString");
            using (var conn = new SqlConnection(connectionString))
            {
                conn.Open();

                string sql = vm.ExtendedCountriesDisplayFeatureOn
                    ? "SELECT Alpha2,Name,Alpha3,Numeric FROM ISO_3166_2 WHERE Name LIKE @searchString"
                    : "SELECT Alpha2,Name FROM ISO_3166_2 WHERE Name LIKE @searchString";

                using (var cmd = new SqlCommand(sql, conn))
                {
                    searchString = searchString ?? string.Empty;
                    cmd.Parameters.AddWithValue("searchString", searchString + "%");
                    using (var reader = await cmd.ExecuteReaderAsync())
                    {
                        while (await reader.ReadAsync())
                        {
                            if (vm.ExtendedCountriesDisplayFeatureOn)
                            {
                                vm.Nations.Add(new Nation
                                {
                                    Alpha2 = reader.GetString(0),
                                    EnglishName = reader.GetString(1),
                                    Alpha3 = reader.GetString(2),
                                    Numeric = reader.GetString(3)
                                });
                            }
                            else
                            {
                                vm.Nations.Add(new Nation
                                {
                                    Alpha2 = reader.GetString(0),
                                    EnglishName = reader.GetString(1)
                                });
                            }
                        }
                    }
                }
            }

            return View(vm);
        }

        private void TrackUserQuery(string searchString)
        {
            if (searchString.Length > 2)
            {
                TelemetryClient.TrackEvent("Longer user query",
                    new Dictionary<string, string> {
                        { "QueryLength", searchString.Length.ToString() } // TIP: no blanks in key
                    });
            }
        }
    }
}
