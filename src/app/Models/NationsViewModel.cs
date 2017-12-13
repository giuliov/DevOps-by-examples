using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace app.Models
{
    public class NationsViewModel
    {
        // data
        public IList<Nation> Nations { get; set; }

        // configuration
        public bool ShowTimeFeatureOn { get; set; }
        public bool ExtendedCountriesDisplayFeatureOn { get; set; }
    }
}
