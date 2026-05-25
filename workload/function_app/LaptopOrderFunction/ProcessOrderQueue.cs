using System;
using Microsoft.Data.SqlClient;
using System.Net.Http;
using System.Text;
using System.Text.Json;
using System.Threading.Tasks;

using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;

namespace LaptopOrderFunction
{
    public class ProcessOrderQueue
    {
        private readonly ILogger _logger;

        public ProcessOrderQueue(ILoggerFactory loggerFactory)
        {
            _logger = loggerFactory.CreateLogger<ProcessOrderQueue>();
        }

        [Function("ProcessOrderQueue")]
        public async Task Run(
            [QueueTrigger("orders-queue")] string queueMessage)
        {
            _logger.LogInformation("===== QUEUE TRIGGER STARTED =====");

            try
            {
                _logger.LogInformation($"RAW MESSAGE: {queueMessage}");

                // Deserialize queue message
                var order = JsonSerializer.Deserialize<OrderMessage>(
                    queueMessage,
                    new JsonSerializerOptions
                    {
                        PropertyNameCaseInsensitive = true
                    });

                if (order == null)
                {
                    _logger.LogError("Order object is NULL");
                    return;
                }

                _logger.LogInformation("JSON DESERIALIZATION SUCCESS");

                // Environment variables
                string? sqlConnectionString =
                    Environment.GetEnvironmentVariable("SQL_CONNECTION_STRING");

                string? logicAppUrl =
                    Environment.GetEnvironmentVariable("LOGIC_APP_CALLBACK_URL");

                if (string.IsNullOrEmpty(sqlConnectionString))
                {
                    _logger.LogError("SQL_CONNECTION_STRING is missing");
                    return;
                }

                // Save to SQL DB
                using (SqlConnection connection = new SqlConnection(sqlConnectionString))
                {
                    await connection.OpenAsync();

                    _logger.LogInformation("SQL CONNECTION SUCCESS");

                    string query = @"
                        INSERT INTO Orders
                        (
                            CustomerName,
                            CustomerAddress,
                            Email,
                            MobileNo,
                            LaptopModel,
                            RAM,
                            CPU,
                            Quantity
                        )
                        VALUES
                        (
                            @CustomerName,
                            @CustomerAddress,
                            @Email,
                            @MobileNo,
                            @LaptopModel,
                            @RAM,
                            @CPU,
                            @Quantity
                        )";

                    using (SqlCommand command = new SqlCommand(query, connection))
                    {
                        command.Parameters.AddWithValue("@CustomerName", order.CustomerName);
                        command.Parameters.AddWithValue("@CustomerAddress", order.CustomerAddress);
                        command.Parameters.AddWithValue("@Email", order.Email);
                        command.Parameters.AddWithValue("@MobileNo", order.MobileNo);
                        command.Parameters.AddWithValue("@LaptopModel", order.LaptopModel);
                        command.Parameters.AddWithValue("@RAM", order.RAM);
                        command.Parameters.AddWithValue("@CPU", order.CPU);
                        command.Parameters.AddWithValue("@Quantity", order.Quantity);

                        int rows = await command.ExecuteNonQueryAsync();

                        _logger.LogInformation($"SQL INSERT SUCCESS. Rows inserted: {rows}");

                        // Logic App Payload
                        var logicPayload = new
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
                            status = "SUCCESS",
                            createdDate = DateTime.UtcNow
                        };

                        // Send to Logic App
                        if (!string.IsNullOrEmpty(logicAppUrl))
                        {
                            using (HttpClient client = new HttpClient())
                            {
                                var jsonContent = new StringContent(
                                    JsonSerializer.Serialize(logicPayload),
                                    Encoding.UTF8,
                                    "application/json");

                                HttpResponseMessage response =
                                    await client.PostAsync(logicAppUrl, jsonContent);

                                _logger.LogInformation(
                                    $"Logic App Status: {response.StatusCode}");
                            }
                        }
                    }
                }

                _logger.LogInformation("===== FUNCTION COMPLETED SUCCESSFULLY =====");
            }
            catch (Exception ex)
            {
                _logger.LogError($"FUNCTION ERROR: {ex}");
                throw;
            }
        }
    }

    public class OrderMessage
    {
        public string? CustomerName { get; set; }

        public string? CustomerAddress { get; set; }

        public string? Email { get; set; }

        public string? MobileNo { get; set; }

        public string? LaptopModel { get; set; }

        public string? RAM { get; set; }

        public string? CPU { get; set; }

        public int Quantity { get; set; }
    }
}