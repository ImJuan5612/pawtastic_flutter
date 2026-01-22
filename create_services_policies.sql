
-- Política de lectura: los usuarios pueden leer los servicios de sus mascotas
CREATE POLICY 'Usuarios pueden leer sus servicios' ON services
  FOR SELECT USING (auth.uid() = user_id);

-- Política de inserción: los usuarios pueden crear servicios para sus mascotas
CREATE POLICY 'Usuarios pueden crear servicios' ON services
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Política de actualización: los usuarios pueden actualizar los servicios de sus mascotas
CREATE POLICY 'Usuarios pueden actualizar sus servicios' ON services
  FOR UPDATE USING (auth.uid() = user_id);

-- Política de eliminación: los usuarios pueden eliminar los servicios de sus mascotas
CREATE POLICY 'Usuarios pueden eliminar sus servicios' ON services
  FOR DELETE USING (auth.uid() = user_id);

-- Habilitar RLS
ALTER TABLE services ENABLE ROW LEVEL SECURITY;

