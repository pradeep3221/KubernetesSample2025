using Microsoft.AspNetCore.Authentication.JwtBearer;
using Ocelot.DependencyInjection;
using Ocelot.Middleware;
using Ocelot.Provider.Polly;
using OpenTelemetry.Metrics;
using Shared.Observability;
using Serilog;

var builder = WebApplication.CreateBuilder(args);

// Add Observability (includes Serilog configuration)
builder.Services.AddObservability(builder.Configuration, "api-gateway", "1.0.0");

// Use Serilog for request logging
builder.Host.UseSerilog();

// Add configuration for Ocelot
builder.Configuration.AddJsonFile("ocelot.json", optional: false, reloadOnChange: true);

// Log the configuration
Log.Information("Ocelot configuration loaded from ocelot.json");

// Add Authentication
var keycloakAuthority = builder.Configuration["Keycloak:Authority"] ?? "http://localhost:8080/realms/microservices";

builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer("Keycloak", options =>
    {
        options.Authority = keycloakAuthority;
        options.RequireHttpsMetadata = false;
        options.TokenValidationParameters = new Microsoft.IdentityModel.Tokens.TokenValidationParameters
        {
            ValidateAudience = false,
            ValidateIssuer = true,
            ValidIssuer = keycloakAuthority
        };
    });

// Add Ocelot with rate limiting
builder.Services.AddOcelot()
    .AddPolly();

// Add Health Checks
builder.Services.AddHealthChecks();

// Add CORS
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyMethod()
              .AllowAnyHeader();
    });
});

var app = builder.Build();

// Add Serilog request logging middleware
app.UseSerilogRequestLogging(options =>
{
    options.EnrichDiagnosticContext = (diagnosticContext, httpContext) =>
    {
        diagnosticContext.Set("RequestHost", httpContext.Request.Host.Value);
        diagnosticContext.Set("RequestPath", httpContext.Request.Path);
    };
});

Log.Information("Starting API Gateway...");

// Use CORS
app.UseCors("AllowAll");

// Add Authentication and Authorization middleware
app.UseAuthentication();
app.UseAuthorization();

Log.Information("API Gateway configured, starting Ocelot...");

// Log the routes from configuration
var routes = builder.Configuration.GetSection("Routes").GetChildren();
Log.Information($"Found {routes.Count()} routes in configuration");
foreach (var route in routes)
{
    var upstream = route["UpstreamPathTemplate"];
    var downstream = route["DownstreamPathTemplate"];
    Log.Information($"Route: {upstream} -> {downstream}");
}

// Use Ocelot (must be before static files)
await app.UseOcelot();

// Serve static files (for Swagger landing page) - after Ocelot
app.UseDefaultFiles();
app.UseStaticFiles();

// Prometheus metrics
app.MapPrometheusScrapingEndpoint();

// Health checks
app.MapHealthChecks("/health");

Log.Information("API Gateway started successfully");

try
{
    app.Run();
}
catch (Exception ex)
{
    Log.Fatal(ex, "API Gateway terminated unexpectedly");
}
finally
{
    Log.CloseAndFlush();
}

