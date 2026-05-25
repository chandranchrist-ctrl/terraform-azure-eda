using LaptopStoreApi.Services;

var builder = WebApplication.CreateBuilder(args);

// ---------------- SERVICES ----------------
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();
builder.Services.AddSingleton<QueueService>();

// ---------------- CORS ----------------
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowFrontend", policy =>
    {
        policy.SetIsOriginAllowed(origin =>
        {
            // allow all your frontend variants safely
            return origin.EndsWith("azurestaticapps.net")
                   || origin.EndsWith("hbcdev.co.in");
        })
        .AllowAnyHeader()
        .AllowAnyMethod();
    });
});

var app = builder.Build();

// ---------------- PIPELINE ORDER (CRITICAL) ----------------

// Swagger
app.UseSwagger();
app.UseSwaggerUI();

// Routing MUST be first for CORS to work correctly
app.UseRouting();

// CORS must come AFTER routing but BEFORE endpoints
app.UseCors("AllowFrontend");

app.UseAuthorization();

// Controllers
app.MapControllers();

// Health check
app.MapGet("/health", () => "Healthy");

// Sample endpoint
var summaries = new[]
{
    "Freezing", "Bracing", "Chilly", "Cool",
    "Mild", "Warm", "Balmy", "Hot",
    "Sweltering", "Scorching"
};

app.MapGet("/weatherforecast", () =>
{
    var forecast = Enumerable.Range(1, 5).Select(index =>
        new WeatherForecast
        (
            DateOnly.FromDateTime(DateTime.Now.AddDays(index)),
            Random.Shared.Next(-20, 55),
            summaries[Random.Shared.Next(summaries.Length)]
        ))
        .ToArray();

    return forecast;
})
.WithName("GetWeatherForecast")
.WithOpenApi();

app.Run();

record WeatherForecast(DateOnly Date, int TemperatureC, string? Summary)
{
    public int TemperatureF => 32 + (int)(TemperatureC / 0.5556);
}