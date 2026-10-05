import { createContext, useContext, useEffect, useState } from "react";

const CartContext = createContext(null);

export function CartProvider({ children }) {
  const [items, setItems] = useState(() => {
    const raw = localStorage.getItem("cart");
    return raw ? JSON.parse(raw) : [];
  });

  useEffect(() => {
    localStorage.setItem("cart", JSON.stringify(items));
  }, [items]);

  function agregar(producto, cantidad = 1) {
    setItems((prev) => {
      const existe = prev.find((i) => i.productoId === producto.id);
      if (existe) {
        return prev.map((i) =>
          i.productoId === producto.id ? { ...i, cantidad: i.cantidad + cantidad } : i
        );
      }
      return [...prev, {
        productoId: producto.id, nombre: producto.nombre,
        precio: Number(producto.precio), cantidad,
      }];
    });
  }

  function quitar(id) {
    setItems((prev) => prev.filter((i) => i.productoId !== id));
  }

  function actualizarCantidad(id, cantidad) {
    if (cantidad <= 0) return quitar(id);
    setItems((prev) => prev.map((i) => (i.productoId === id ? { ...i, cantidad } : i)));
  }

  function vaciar() { setItems([]); }

  const total = items.reduce((s, i) => s + i.precio * i.cantidad, 0);
  const cantidadTotal = items.reduce((s, i) => s + i.cantidad, 0);

  return (
    <CartContext.Provider value={{ items, total, cantidadTotal, agregar, quitar, actualizarCantidad, vaciar }}>
      {children}
    </CartContext.Provider>
  );
}

export function useCart() {
  const ctx = useContext(CartContext);
  if (!ctx) throw new Error("useCart fuera de CartProvider");
  return ctx;
}
