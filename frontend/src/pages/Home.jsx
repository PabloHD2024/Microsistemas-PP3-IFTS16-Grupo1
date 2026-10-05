import { Link } from "react-router-dom";
export default function Home() {
  return (
    <div style={{ padding: "3rem", textAlign: "center" }}>
      <h1>Bienvenido al E-commerce</h1>
      <p>Microservicios + API Gateway + React</p>
      <Link to="/catalogo" style={{ fontSize: "1.2rem" }}>Ver catálogo →</Link>
    </div>
  );
}
