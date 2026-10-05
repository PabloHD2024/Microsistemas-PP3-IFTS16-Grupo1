import { Navigate, useLocation } from "react-router-dom";
import { useAuth } from "../context/AuthContext.jsx";

export default function ProtectedRoute({ children, soloAdmin = false }) {
  const { autenticado, esAdmin } = useAuth();
  const location = useLocation();

  if (!autenticado) {
    return <Navigate to="/login" state={{ from: location.pathname }} replace />;
  }
  if (soloAdmin && !esAdmin) return <Navigate to="/" replace />;
  return children;
}
