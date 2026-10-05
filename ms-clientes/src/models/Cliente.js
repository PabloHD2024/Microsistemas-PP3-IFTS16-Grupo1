import mongoose from "mongoose";

const direccionSchema = new mongoose.Schema(
  {
    etiqueta: { type: String, enum: ["casa", "trabajo", "otra"], default: "casa" },
    calle: { type: String, required: true, trim: true },
    numero: { type: String, required: true },
    piso: { type: String, default: null },
    depto: { type: String, default: null },
    ciudad: { type: String, required: true },
    provincia: { type: String, required: true },
    codigoPostal: { type: String, required: true },
    pais: { type: String, default: "Argentina" },
    esPredeterminada: { type: Boolean, default: false },
    coordenadas: {
      lat: { type: Number, default: null },
      lng: { type: Number, default: null },
    },
  },
  { _id: true, timestamps: true }
);

const preferenciasSchema = new mongoose.Schema(
  {
    idioma: { type: String, enum: ["es", "en", "pt"], default: "es" },
    notificacionesEmail: { type: Boolean, default: true },
    newsletter: { type: Boolean, default: false },
  },
  { _id: false }
);

const clienteSchema = new mongoose.Schema(
  {
    usuarioId: { type: String, required: true, unique: true, index: true },
    nombre: { type: String, required: true, trim: true },
    apellido: { type: String, required: true, trim: true },
    dni: { type: String, required: true, unique: true, match: /^\d{7,8}$/ },
    telefono: { type: String, trim: true },
    fechaNacimiento: { type: Date },
    direcciones: { type: [direccionSchema], default: [] },
    preferencias: { type: preferenciasSchema, default: () => ({}) },
    activo: { type: Boolean, default: true },
  },
  { timestamps: true }
);

clienteSchema.pre("save", function (next) {
  if (this.isModified("direcciones")) {
    const preds = this.direcciones.filter((d) => d.esPredeterminada);
    if (preds.length > 1) {
      const ultima = preds[preds.length - 1]._id;
      this.direcciones.forEach((d) => { d.esPredeterminada = d._id.equals(ultima); });
    }
  }
  next();
});

export default mongoose.model("Cliente", clienteSchema);
