using Microsoft.AspNetCore.Mvc;
using LaptopStoreApi.Models;
using LaptopStoreApi.Services;

namespace LaptopStoreApi.Controllers;

[ApiController]
[Route("api/[controller]")]
public class OrderController : ControllerBase
{
    private readonly QueueService _queueService;

    public OrderController(QueueService queueService)
    {
        _queueService = queueService;
    }

    [HttpPost]
    public async Task<IActionResult> CreateOrder([FromBody] Order order)
    {
        if (order == null)
            return BadRequest("Invalid order");

        await _queueService.SendMessageAsync(order);

        return Ok(new { message = "Order sent to queue successfully" });
    }
}