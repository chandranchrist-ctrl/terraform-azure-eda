using Azure.Storage.Queues;
using System.Text.Json;
using Microsoft.Extensions.Configuration;

namespace LaptopOrderFunction.Services;

public class QueueService
{
    private readonly IConfiguration _config;

    public QueueService(IConfiguration config)
    {
        _config = config;
    }

    public async Task SendMessageAsync(object order)
    {
        var conn = _config["AzureWebJobsStorage"];
        var queueName = "orders-queue";

        var queueClient = new QueueClient(conn, queueName);
        await queueClient.CreateIfNotExistsAsync();

        var message = JsonSerializer.Serialize(order);
        await queueClient.SendMessageAsync(message);
    }
}