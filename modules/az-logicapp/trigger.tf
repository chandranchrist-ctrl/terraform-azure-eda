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
ORDER DETAILS

Order ID: @{triggerBody()['orderId']}

Customer Name: @{triggerBody()['customerName']}
Address: @{triggerBody()['customerAddress']}
Email: @{triggerBody()['email']}
Mobile: @{triggerBody()['mobileNo']}

Laptop Model: @{triggerBody()['laptopModel']}
RAM: @{triggerBody()['ram']}
CPU: @{triggerBody()['cpu']}
Quantity: @{triggerBody()['quantity']}

Status: @{triggerBody()['status']}
Created Date: @{triggerBody()['createdDate']}
BODY
      }
    }

    runAfter = {}
  })
}