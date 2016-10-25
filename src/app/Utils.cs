using System;
using System.Collections.Generic;
using System.Linq;
using System.Reflection;
using System.Threading.Tasks;

namespace app
{
    public class Utils
    {
        static public T GetCustomAttribute<T>()
                where T : Attribute
        {
            return typeof(Utils).GetTypeInfo().Assembly.GetCustomAttribute<T>() as T;
        }
    }
}
