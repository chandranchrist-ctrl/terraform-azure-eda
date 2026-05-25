import { useState } from "react";

const API_BASE_URL = process.env.REACT_APP_API_URL;

function App() {
  const [order, setOrder] = useState({
    customerName: "",
    customerAddress: "",
    email: "",
    mobileNo: "",
    laptopModel: "",
    ram: "",
    cpu: "",
    quantity: ""
  });

  const [loading, setLoading] = useState(false);

  const handleChange = (e) => {
    setOrder({
      ...order,
      [e.target.name]: e.target.value
    });
  };

  const submitOrder = async () => {
    setLoading(true);

    try {
      const response = await fetch(`${API_BASE_URL}/api/order`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json"
        },
        body: JSON.stringify(order)
      });

      if (!response.ok) {
        throw new Error("Failed to place order");
      }

      const data = await response.json();

      alert("✅ " + data.message);

      // reset form
      setOrder({
        customerName: "",
        customerAddress: "",
        email: "",
        mobileNo: "",
        laptopModel: "",
        ram: "",
        cpu: "",
        quantity: 1
      });

    } catch (error) {
      console.error(error);
      alert("❌ Order failed. Please try again.");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div style={styles.page}>
      <div style={styles.overlay}></div>

      <div style={styles.container}>
        <h1 style={styles.title}>Laptop Store Order</h1>

        <div style={styles.form}>

          <div style={styles.row}>
            <label>Customer Name</label>
            <input
              name="customerName"
              value={order.customerName}
              onChange={handleChange}
            />
          </div>

          <div style={styles.row}>
            <label>Customer Address</label>
            <input
              name="customerAddress"
              value={order.customerAddress}
              onChange={handleChange}
            />
          </div>

          <div style={styles.row}>
            <label>Email</label>
            <input
              name="email"
              value={order.email}
              onChange={handleChange}
            />
          </div>

          <div style={styles.row}>
            <label>Mobile No</label>
            <input
              name="mobileNo"
              value={order.mobileNo}
              onChange={handleChange}
            />
          </div>

          <div style={styles.row}>
            <label>Laptop Model</label>
            <input
              name="laptopModel"
              value={order.laptopModel}
              onChange={handleChange}
            />
          </div>

          <div style={styles.row}>
            <label>RAM</label>
            <input
              name="ram"
              value={order.ram}
              onChange={handleChange}
            />
          </div>

          <div style={styles.row}>
            <label>CPU</label>
            <input
              name="cpu"
              value={order.cpu}
              onChange={handleChange}
            />
          </div>

          <div style={styles.row}>
            <label>Quantity</label>
            <input
              type="number"
              name="quantity"
              value={order.quantity}
              onChange={handleChange}
            />
          </div>

          <button
            style={styles.button}
            onClick={submitOrder}
            disabled={loading}
          >
            {loading ? "Placing Order..." : "Place Order"}
          </button>

        </div>
      </div>
    </div>
  );
}

const styles = {
  page: {
    height: "100vh",
    display: "flex",
    justifyContent: "center",
    alignItems: "center",
    backgroundImage:
      "url('https://images.unsplash.com/photo-1517336714731-489689fd1ca8')",
    backgroundSize: "cover",
    backgroundPosition: "center",
    fontFamily: "Arial"
  },

  overlay: {
    position: "absolute",
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
    backgroundColor: "rgba(0,0,0,0.6)"
  },

  container: {
    position: "relative",
    zIndex: 2,
    width: "450px",
    backgroundColor: "white",
    padding: "25px",
    borderRadius: "12px",
    boxShadow: "0 0 20px rgba(0,0,0,0.3)"
  },

  title: {
    textAlign: "center",
    marginBottom: "20px"
  },

  form: {
    display: "flex",
    flexDirection: "column",
    gap: "12px"
  },

  row: {
    display: "flex",
    flexDirection: "column"
  },

  button: {
    marginTop: "10px",
    padding: "10px",
    backgroundColor: "#0078D4",
    color: "white",
    border: "none",
    borderRadius: "6px",
    cursor: "pointer"
  }
};

export default App;