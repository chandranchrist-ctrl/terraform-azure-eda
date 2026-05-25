using Azure.Identity;
using Azure.Storage.Queues;
using System.Text;
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
        var accountName = _config["AzureQueue:AccountName"];
        var queueName = _config["AzureQueue:QueueName"];

        // Build Queue URI (NO connection string)
        var queueUri = new Uri($"https://{accountName}.queue.core.windows.net/{queueName}");

        // Managed Identity authentication
        var queueClient = new QueueClient(queueUri, new DefaultAzureCredential());

        await queueClient.CreateIfNotExistsAsync();

        var message = JsonSerializer.Serialize(order);

        var base64Message = Convert.ToBase64String(Encoding.UTF8.GetBytes(message));

        await queueClient.SendMessageAsync(base64Message);
    }
}

// using Azure.Storage.Queues;
// using System.Text.Json;

// namespace LaptopStoreApi.Services;

// public class QueueService
// {
//     private readonly IConfiguration _config;

//     public QueueService(IConfiguration config)
//     {
//         _config = config;
//     }

// public async Task SendMessageAsync(object order)
// {
//     var conn = _config["AzureQueue:ConnectionString"];
//     var queueName = _config["AzureQueue:QueueName"];

//     var queueClient = new QueueClient(conn, queueName);
//     await queueClient.CreateIfNotExistsAsync();

//     var message = JsonSerializer.Serialize(order);

//     var base64Message = Convert.ToBase64String(System.Text.Encoding.UTF8.GetBytes(message));

//     await queueClient.SendMessageAsync(base64Message);
// }
// }