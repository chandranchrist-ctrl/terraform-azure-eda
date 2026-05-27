# Defines HTTP trigger for Logic App to receive order events from Function App and start workflow execution
resource "azurerm_logic_app_trigger_http_request" "order_trigger" {
  name         = "order-notification-trigger"
  logic_app_id = azurerm_logic_app_workflow.logic_app.id

  schema = jsonencode({
    type = "object"
    properties = {
      orderId = { type = "string" }

      customerName    = { type = "string" }
      customerAddress = { type = "string" }
      email           = { type = "string" }
      mobileNo        = { type = "string" }

      laptopModel = { type = "string" }
      ram         = { type = "string" }
      cpu         = { type = "string" }
      quantity    = { type = "integer" }

      status      = { type = "string" }
      createdDate = { type = "string" }
    }
  })
}

# Sends formatted HTML email via Gmail connector when a new order is received through Logic App workflow
resource "azurerm_logic_app_action_custom" "send_email" {
  name         = "send-order-email"
  logic_app_id = azurerm_logic_app_workflow.logic_app.id

  body = jsonencode({
    type = "ApiConnection"

    inputs = {
      host = {
        connection = {
          name = "@parameters('$connections')['gmail']['connectionId']"
        }
      }

      method = "post"

      path = "/v2/Mail"

      body = {
        To = join(";", var.notification_emails)

        Subject = "New Order Created"

        Body = <<BODY
<div style="font-family: Arial, Helvetica, sans-serif; font-size: 14px; color: #333333; line-height: 1.6;">

    <h1 style="color: #1f4e78; font-size: 24px; margin-bottom: 10px;">
        New Laptop Order Created
    </h1>

    <hr style="border: 1px solid #d9d9d9;"/>

    <h2 style="font-size: 18px; color: #2f75b5; margin-top: 20px;">
        Order Information
    </h2>

    <p>
        <b>Order ID:</b>
        @{triggerBody()['orderId']}
    </p>

    <p>
        <b>Status:</b>
        <span style="color: green; font-weight: bold;">
            @{triggerBody()['status']}
        </span>
    </p>

    <p>
        <b>Created Date:</b>
        @{triggerBody()['createdDate']}
    </p>

    <hr style="border: 1px solid #eeeeee;"/>

    <h2 style="font-size: 18px; color: #2f75b5;">
        Customer Details
    </h2>

    <table style="border-collapse: collapse; width: 100%;">

        <tr>
            <td style="padding: 8px; font-weight: bold; width: 180px;">
                Customer Name
            </td>
            <td style="padding: 8px;">
                @{triggerBody()['customerName']}
            </td>
        </tr>

        <tr style="background-color: #f7f7f7;">
            <td style="padding: 8px; font-weight: bold;">
                Address
            </td>
            <td style="padding: 8px;">
                @{triggerBody()['customerAddress']}
            </td>
        </tr>

        <tr>
            <td style="padding: 8px; font-weight: bold;">
                Email
            </td>
            <td style="padding: 8px;">
                @{triggerBody()['email']}
            </td>
        </tr>

        <tr style="background-color: #f7f7f7;">
            <td style="padding: 8px; font-weight: bold;">
                Mobile
            </td>
            <td style="padding: 8px;">
                @{triggerBody()['mobileNo']}
            </td>
        </tr>

    </table>

    <hr style="border: 1px solid #eeeeee; margin-top: 20px;"/>

    <h2 style="font-size: 18px; color: #2f75b5;">
        Laptop Configuration
    </h2>

    <table style="border-collapse: collapse; width: 100%;">

        <tr>
            <td style="padding: 8px; font-weight: bold; width: 180px;">
                Laptop Model
            </td>
            <td style="padding: 8px;">
                @{triggerBody()['laptopModel']}
            </td>
        </tr>

        <tr style="background-color: #f7f7f7;">
            <td style="padding: 8px; font-weight: bold;">
                RAM
            </td>
            <td style="padding: 8px;">
                @{triggerBody()['ram']}
            </td>
        </tr>

        <tr>
            <td style="padding: 8px; font-weight: bold;">
                CPU
            </td>
            <td style="padding: 8px;">
                @{triggerBody()['cpu']}
            </td>
        </tr>

        <tr style="background-color: #f7f7f7;">
            <td style="padding: 8px; font-weight: bold;">
                Quantity
            </td>
            <td style="padding: 8px;">
                @{triggerBody()['quantity']}
            </td>
        </tr>

    </table>

    <br/>

    <div style="margin-top: 30px; font-size: 12px; color: #777777;">
        This is an automated email generated from the Azure EDA Platform.
    </div>

</div>
BODY

      }
    }

    runAfter = {}
  })
}