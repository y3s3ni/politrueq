# Spec: Corregir Visibilidad de Productos Pendientes

## 📋 Problema

**Estado actual:**
- Existen 16 productos con `estado_aprobacion = 'pendiente'` en la tabla `productos_unificados`
- La pantalla "Revisión de Objetos" (`approval_screen.dart`) muestra "No hay objetos pendientes"
- Los moderadores/administradores no pueden ver los productos para aprobarlos

**Causa raíz:**
Las políticas RLS (Row Level Security) actuales son demasiado restrictivas y no permiten que usuarios autenticados vean productos pendientes.

## 🎯 Objetivo

Permitir que moderadores y administradores puedan ver y gestionar productos pendientes en la pantalla de revisión.

## ✅ Criterios de Aceptación

1. Los productos con `estado_aprobacion = 'pendiente'` deben ser visibles en `approval_screen.dart`
2. Los moderadores/admins deben poder aprobar productos
3. Los moderadores/admins deben poder rechazar productos
4. Los moderadores/admins deben poder ajustar puntos al aprobar
5. Las políticas RLS deben ser funcionales pero seguras

## 🔧 Solución Propuesta

### Opción 1: Aplicar Políticas RLS Simplificadas (RECOMENDADO)

Ejecutar el script `POLITICAS_RLS_SIMPLES.sql` que:
- Elimina todas las políticas existentes
- Crea 6 políticas simples y funcionales
- Permite a usuarios autenticados ver todos los productos (necesario para moderadores)
- Mantiene restricciones de creación/edición

**Ventajas:**
- ✅ Solución probada y documentada
- ✅ Políticas más simples de mantener
- ✅ Funciona para desarrollo y producción

**Desventajas:**
- ⚠️ Usuarios autenticados pueden ver todos los productos (incluso pendientes)
- ⚠️ La validación de roles debe hacerse en la aplicación

### Opción 2: Agregar Política Específica para Pendientes

Ejecutar solo la política que falta:

```sql
CREATE POLICY "ver_pendientes_autenticados"
ON productos_unificados FOR SELECT
TO authenticated
USING (estado_aprobacion = 'pendiente');
```

**Ventajas:**
- ✅ Cambio mínimo
- ✅ Mantiene políticas existentes

**Desventajas:**
- ⚠️ Puede haber conflictos con políticas existentes
- ⚠️ Más difícil de debuggear

## 📝 Pasos de Implementación

### Paso 1: Aplicar Políticas RLS Simplificadas

1. Abrir Supabase SQL Editor
2. Copiar y pegar el contenido de `POLITICAS_RLS_SIMPLES.sql`
3. Ejecutar el script completo
4. Verificar que se crearon 6 políticas

### Paso 2: Verificar en la Base de Datos

Ejecutar en SQL Editor:

```sql
-- Ver políticas creadas
SELECT policyname, cmd, roles
FROM pg_policies
WHERE tablename = 'productos_unificados'
ORDER BY policyname;

-- Ver productos pendientes
SELECT id, nombre, estado_aprobacion, COUNT(*) OVER() as total
FROM productos_unificados
WHERE estado_aprobacion = 'pendiente'
LIMIT 5;
```

**Resultado esperado:**
- 6 políticas listadas
- Al menos 16 productos pendientes

### Paso 3: Hot Restart de la App

En el terminal de Flutter:
```
R (mayúscula)
```

O detener y volver a ejecutar:
```
flutter run
```

### Paso 4: Verificar en la App

1. Iniciar sesión como moderador/admin
2. Ir a "Revisión de Objetos"
3. Verificar que aparecen los 16 productos pendientes
4. Probar aprobar un producto
5. Probar rechazar un producto

## 🧪 Casos de Prueba

### Test 1: Ver Productos Pendientes
- **Acción:** Abrir pantalla "Revisión de Objetos"
- **Esperado:** Se muestran 16 productos con estado "pendiente"
- **Actual:** "No hay objetos pendientes" ❌

### Test 2: Aprobar Producto
- **Acción:** Click en "Aprobar" en un producto
- **Esperado:** Producto cambia a estado "aprobado"
- **Actual:** No se puede probar (productos no visibles) ❌

### Test 3: Rechazar Producto
- **Acción:** Click en "Rechazar" con motivo
- **Esperado:** Producto cambia a estado "rechazado"
- **Actual:** No se puede probar (productos no visibles) ❌

### Test 4: Ajustar Puntos
- **Acción:** Aprobar producto ajustando puntos
- **Esperado:** Producto aprobado con puntos ajustados
- **Actual:** No se puede probar (productos no visibles) ❌

## 🔍 Debugging

Si después de aplicar las políticas simplificadas aún no funciona:

### 1. Verificar Autenticación
```dart
final userId = client.auth.currentUser?.id;
print('User ID: $userId');
```

### 2. Verificar Respuesta del Servicio
```dart
final result = await ProductosUnificadosService.getProductosPendientes();
print('Success: ${result['success']}');
print('Data length: ${result['data'].length}');
print('Message: ${result['message']}');
```

### 3. Verificar Errores en Consola
Buscar mensajes de error relacionados con:
- `PostgrestException`
- `RLS policy violation`
- `permission denied`

### 4. Verificar Políticas en Supabase
Dashboard → Authentication → Policies → productos_unificados

## 📚 Archivos Relacionados

- `lib/screens/approval_screen.dart` - Pantalla de revisión
- `lib/services/productos_unificados_service.dart` - Servicio de productos
- `POLITICAS_RLS_SIMPLES.sql` - Script de políticas simplificadas
- `VERIFICAR_Y_CORREGIR_RLS.sql` - Script de verificación
- `FLUJO_APROBACION_PRODUCTOS.md` - Documentación del flujo

## 🚀 Próximos Pasos

Después de corregir la visibilidad:

1. ✅ Probar flujo completo de aprobación
2. ✅ Probar flujo completo de rechazo
3. ✅ Probar ajuste de puntos
4. ✅ Verificar que productos aprobados aparecen en catálogo
5. ✅ Verificar que productos rechazados vuelven al usuario
6. 🔄 Implementar notificaciones (futuro)
7. 🔄 Implementar validación de roles en backend (futuro)

## 📊 Estado Actual

- [x] Tabla `productos_unificados` creada
- [x] 16 productos migrados con estado 'pendiente'
- [x] Servicio `ProductosUnificadosService` implementado
- [x] Pantalla `approval_screen.dart` implementada
- [x] Políticas RLS configuradas (pero restrictivas)
- [ ] **Productos pendientes visibles en pantalla** ← BLOQUEADO
- [ ] Flujo de aprobación probado
- [ ] Flujo de rechazo probado
- [ ] Ajuste de puntos probado

## 🎯 Decisión Recomendada

**Aplicar `POLITICAS_RLS_SIMPLES.sql` inmediatamente** porque:

1. Es la solución más rápida y probada
2. Las políticas están documentadas y son fáciles de entender
3. Permite continuar con el desarrollo sin bloqueos
4. Se puede refinar la seguridad más adelante si es necesario
5. La validación de roles en la app es suficiente para MVP

---

**Creado:** 2025-12-07
**Estado:** Pendiente de aplicación
**Prioridad:** Alta (bloqueante)
