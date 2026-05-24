namespace LaptopStoreApi.Models;

public class Order
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