using Azure.Storage.Queues;
using System.Text.Json;

namespace LaptopStoreApi.Services;

public class QueueService
{
    private readonly IConfiguration _config;

    public QueueService(IConfiguration config)
    {
        _config = config;
    }

public async Task SendMessageAsync(object order)
{
    var conn = _config["AzureQueue:ConnectionString"];
    var queueName = _config["AzureQueue:QueueName"];

    var queueClient = new QueueClient(conn, queueName);
    await queueClient.CreateIfNotExistsAsync();

    var message = JsonSerializer.Serialize(order);

    var base64Message = Convert.ToBase64String(System.Text.Encoding.UTF8.GetBytes(message));

    await queueClient.SendMessageAsync(base64Message);
}
}