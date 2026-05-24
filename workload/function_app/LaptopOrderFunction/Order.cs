namespace LaptopOrderFunction;

public class Order
{
    public string CustomerName { get; set; } = string.Empty;
    public string CustomerAddress { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string MobileNo { get; set; } = string.Empty;
    public string LaptopModel { get; set; } = string.Empty;
    public string RAM { get; set; } = string.Empty;
    public string CPU { get; set; } = string.Empty;
    public int Quantity { get; set; }
}