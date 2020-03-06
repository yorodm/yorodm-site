+++
title = "Microservicios en .NET Core 3.1"
date = 2020-03-06T15:06:47-05:00
tags = ["dotnet core", "microservices", "hostbuilder"]
categories = [""]
draft = false
+++

La nueva versión LTS de .NET Core trae consigo muchas ventajas para el
los desarrolladores de microservicios. Una de las más esperadas es la
estabilización de la API para ejecutar servicios en segundo plano o
*workers* utilizando `Microsoft.Extensions.Hosting`

## ¿Qué son los workers?

Si eres desarrollador de ASP.NET Core debes estar familiarizado con el
paquete `Microsoft.AspNetCore.Hosting` y las clases`WebHostBuilder` y
`WebHost`.

```cs
public class Program
{
    public static void Main(string[] args)
    {
	   var config = new ConfigurationBuilder()
            .AddCommandLine(args)
            .AddJsonFile("hosting.json", optional: true)
			.AddEnvironmentVariables()
            .Build();
      var host = new WebHostBuilder()
           .UseKestrel()
           .UseContentRoot(Directory.GetCurrentDirectory())
		   .UseConfiguration(config)
           .Build();

       host.Run();
    }
 }
```

`WebHost` es responsable de iniciar la configuración, manejar el ciclo
de vida de los servicios, mantener el contenedor de dependencias y
comunicarse/iniciar el servidor web (Kestrel en este caso).

`WebHost` también nos brinda la posibilidad de iniciar servicios en
segundo plano utilizando `IHostedService`.

Si no estás familiarizado con el tema, puedes informarte más con [este excelente post](https://www.stevejgordon.co.uk/asp-net-core-2-ihostedservice
"Implementing IHostedService in ASP.NET Core 2.0")

## Microservicios en aplicaciones de consola.

El nuevo host genérico (`HostBuilder`) no requiere de la maquinaria de
ASP.NET Core, lo cual hace posible crear aplicaciones de consola que
hagan uso de las bondades a las que estamos adaptados.

Veamos un ejemplo:

```cs
 public class Program
    {
        public static void Main(string[] args)
        {
            try {
            CreateHostBuilder(args).Build().Run();
            }
            catch(OperationCanceledException ex)
            {
                Console.WriteLine("-----Terminating-----");
            }
        }

        public static IHostBuilder CreateHostBuilder(string[] args) =>
            Host.CreateDefaultBuilder(args)
                .ConfigureAppConfiguration((hostingContext, config) =>
                {
				    var env = hostingContext.HostingEnvironment.EnvironmentName;
                    var builder = new ConfigurationBuilder()
                            .SetBasePath(Directory.GetCurrentDirectory())
                            .AddJsonFile("settings.json")
                            .AddEnvironmentVariables()
                            .Build();
                })
                .ConfigureServices((hostingContext, services) =>
                {

	                // AWS Configuration
                    var options = hostingContext.Configuration.GetAWSOptions();
                    services.AddDefaultAWSOptions(options);
                    services.AddAWSService<IAmazonSQS>();

                    // Worker Service
                    services.AddHostedService<Worker>();
                    services.AddLogging();

                }).ConfigureLogging((hostcontext, configLogging) =>
                {
                    configLogging.AddConsole();
                    configLogging.AddDebug();
                });
    }
```

El programa anterios hace uso del host genérico para:

1. Cargar la configuración externa (variables de entorno y archivo json).
2. Inicializar un servicio para acceder a SQS.
3. Configurar logs para la consola.
4. Crear un servicio en segundo plano.

La clase `Worker` hereda de `BackgroundService` y es la encargada de
ejecutar la lógica de nuestro microservicio

```cs
public class Worker: BackgroundService {

	 public Worker(ILogger<Worker> logger, IAmazonSQS sqs)
        {
            _logger = logger;
            _sqs = sqs;
	    }

	 protected  async Task ExecuteAsync(int number, CancellationToken cancel)
       {
            while (!cancel.IsCancellationRequested)
            {
				// Procesar mensajes desde SQS
			}
	   }
}
```

## Integración con el sistema operativo

Si desarrollas servicios monolíticos o para software legado, puedes
hacer uso del host genérico para integrar tu aplicación al sistema
operativo.

Para integrarse como servicio a Windows se puede utilizar las
extensiones en `Microsoft.Extensions.Hosting.WindowsService` para
inicializar nuestro programa.

```cs
 Host.CreateDefaultBuilder(args)
        .UseWindowsService()
```

En el casos de Linux sólo están soportadas las distribuciones que incluyen
`Systemd`

```cs
  Host.CreateDefaultBuilder(args)
        .UseSystemd()
```
