CREATE TABLE IF NOT EXISTS productos (
  id SERIAL PRIMARY KEY,
  nombre VARCHAR(150) NOT NULL,
  descripcion TEXT,
  precio NUMERIC(10,2) NOT NULL CHECK (precio >= 0),
  stock INTEGER NOT NULL DEFAULT 0 CHECK (stock >= 0),
  categoria VARCHAR(50),
  imagen_url TEXT,
  activo BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_productos_categoria ON productos(categoria);

INSERT INTO productos (nombre, precio, stock, categoria, descripcion) VALUES
  ('Notebook Lenovo', 850000, 10, 'electronica', 'Ryzen 5, 16GB RAM, 512GB SSD'),
  ('Mouse Logitech', 25000, 50, 'electronica', 'Inalámbrico, 1600 DPI'),
  ('Teclado Mecánico', 75000, 30, 'electronica', 'Redragon, switches rojos'),
  ('Silla Gamer', 320000, 5, 'muebles', 'Reclinable 180°, apoyabrazos 4D'),
  ('Monitor 27"', 480000, 8, 'electronica', 'IPS 144Hz, 2K');
