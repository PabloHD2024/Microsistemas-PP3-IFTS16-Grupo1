<<<<<<< HEAD
# E-commerce Microservicios

Sistema de e-commerce con arquitectura de microservicios + API Gateway.

## Servicios

| Servicio | Puerto | Base de datos |
|---|---|---|
| api-gateway | 3000 | — |
| ms-usuarios | 3001 | MongoDB Atlas |
| ms-productos | 3002 | PostgreSQL |
| ms-clientes | 3003 | MongoDB Atlas |
| ms-pedidos | 3004 | PostgreSQL |
| frontend | 5173 | — |

## Instalación

En cada carpeta de servicio:

```bash
npm install
cp .env.example .env
# Editar .env con credenciales reales
npm run dev
=======
# Microsistemas-PP3-IFTS16-Grupo1
>>>>>>> 37e35665ba686ba6ef0370ac24bd0aa9a169ab49
