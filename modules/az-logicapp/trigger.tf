resource "azurerm_logic_app_trigger_http_request" "order_trigger" {
  name         = "order-notification-trigger"
  logic_app_id = azurerm_logic_app_workflow.logic_app.id

  schema = jsonencode({
    type = "object"

    properties = {
      orderId = {
        type = "string"
      }

      customerName = {
        type = "string"
      }

      email = {
        type = "string"
      }

      product = {
        type = "string"
      }

      quantity = {
        type = "integer"
      }

      status = {
        type = "string"
      }

      createdDate = {
        type = "string"
      }
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
Order ID: @{triggerBody()['orderId']}

Customer: @{triggerBody()['customerName']}

Email: @{triggerBody()['email']}

Product: @{triggerBody()['product']}

Quantity: @{triggerBody()['quantity']}

Status: @{triggerBody()['status']}

Created Date: @{triggerBody()['createdDate']}
BODY
      }
    }

    runAfter = {}
  })
}