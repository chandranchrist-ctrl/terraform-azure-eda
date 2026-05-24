using System.Text.Json;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Configuration;
using System.Net.Http;
using System.Text;

namespace LaptopOrderFunction;

public class ProcessOrderQueue
{
    private readonly ILogger _logger;
    private readonly IConfiguration _config;
    private static readonly HttpClient _httpClient = new HttpClient();

    public ProcessOrderQueue(ILoggerFactory loggerFactory, IConfiguration config)
    {
        _logger = loggerFactory.CreateLogger<ProcessOrderQueue>();
        _config = config;
    }

    [Function("ProcessOrderQueue")]
    public async Task Run(
        [QueueTrigger("orders-queue", Connection = "AzureWebJobsStorage")] string queueMessage)
    {
        _logger.LogInformation($"Queue Trigger Fired: {queueMessage}");

        var order = JsonSerializer.Deserialize<Order>(queueMessage)
            ?? throw new InvalidOperationException("Invalid order payload");

        string connStr =
            _config["ConnectionStrings:SqlConnection"]
            ?? _config["SqlConnection"]
            ?? throw new InvalidOperationException("SQL connection string missing");

        using var conn = new Microsoft.Data.SqlClient.SqlConnection(connStr);
        await conn.OpenAsync();

        var query = @"
            INSERT INTO Orders
            (CustomerName, CustomerAddress, Email, MobileNo, LaptopModel, RAM, CPU, Quantity)
            VALUES
            (@CustomerName, @CustomerAddress, @Email, @MobileNo, @LaptopModel, @RAM, @CPU, @Quantity)";

        using var cmd = new Microsoft.Data.SqlClient.SqlCommand(query, conn);

        cmd.Parameters.AddWithValue("@CustomerName", order.CustomerName);
        cmd.Parameters.AddWithValue("@CustomerAddress", order.CustomerAddress);
        cmd.Parameters.AddWithValue("@Email", order.Email);
        cmd.Parameters.AddWithValue("@MobileNo", order.MobileNo);
        cmd.Parameters.AddWithValue("@LaptopModel", order.LaptopModel);
        cmd.Parameters.AddWithValue("@RAM", order.RAM);
        cmd.Parameters.AddWithValue("@CPU", order.CPU);
        cmd.Parameters.AddWithValue("@Quantity", order.Quantity);

        await cmd.ExecuteNonQueryAsync();

        _logger.LogInformation("Order inserted into SQL successfully");

        // =========================
        // LOGIC APP CALL
        // =========================

        string? logicAppUrl =
            _config["LOGIC_APP_CALLBACK_URL"];

        if (string.IsNullOrWhiteSpace(logicAppUrl))
        {
            _logger.LogWarning("Logic App URL not configured");
            return;
        }

var payload = new
{
    orderId = Guid.NewGuid().ToString(),

    customerName = order.CustomerName,
    customerAddress = order.CustomerAddress,
    email = order.Email,
    mobileNo = order.MobileNo,

    laptopModel = order.LaptopModel,
    ram = order.RAM,
    cpu = order.CPU,
    quantity = order.Quantity,

    status = "Inserted into SQL",
    createdDate = DateTime.UtcNow.ToString("o")
};

        var json = JsonSerializer.Serialize(payload);
        var content = new StringContent(json, Encoding.UTF8, "application/json");

        var response = await _httpClient.PostAsync(logicAppUrl, content);

        if (response.IsSuccessStatusCode)
        {
            _logger.LogInformation("Logic App triggered successfully");
        }
        else
        {
            _logger.LogError($"Logic App failed: {response.StatusCode}");
        }
    }
}