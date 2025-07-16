# Guía de Solución de Problemas - Flutter Charadas

## Problemas de Deformación de UI

### Síntomas Comunes
- Las cartas de categorías se ven comprimidas o estiradas
- Elementos de UI superpuestos o mal posicionados
- Errores de `GraphicBufferAllocator` en los logs
- Pérdida de conexión con el dispositivo (`Lost connection to device`)

### Soluciones Rápidas

#### 1. Hot Reload/Restart
```bash
# En el terminal donde corre flutter run:
r  # Hot reload (mantiene el estado)
R  # Hot restart (reinicia completamente)
```

#### 2. Reiniciar Completamente la App
```bash
# Detener flutter run
q  # Quit

# Reiniciar
flutter run
```

#### 3. Limpiar y Reconstruir
```bash
flutter clean
flutter pub get
flutter run
```

#### 4. Para Dispositivos Android con Problemas Gráficos
```bash
# Reiniciar ADB
adb kill-server
adb start-server
flutter run
```

### Logs de Error Conocidos (Normales)

Estos errores son comunes en algunos dispositivos Android y generalmente no afectan la funcionalidad:

```
E/LB: fail to open file: No such file or directory
E/qdgralloc: GetSize: Unrecognized pixel format
E/GraphicBufferAllocator: Failed to allocate
W/1.raster: type=1400 audit
```

### Prevención

1. **Evitar rotaciones rápidas** durante la navegación
2. **Esperar** que termine la animación antes de navegar
3. **Usar Hot Reload** en lugar de Hot Restart cuando sea posible
4. **Mantener la app actualizada** con `flutter upgrade`

### Si los Problemas Persisten

1. Verificar que Flutter esté actualizado: `flutter doctor`
2. Probar en otro dispositivo/emulador
3. Reportar el problema con capturas de pantalla y logs

### Mejoras Implementadas

El código ahora incluye:
- ✅ Validaciones robustas de parámetros
- ✅ Manejo de errores en navegación
- ✅ Fallbacks seguros para valores inválidos
- ✅ Optimizaciones de renderizado con RepaintBoundary
- ✅ Cache de elementos para mejor rendimiento
- ✅ Física de scroll mejorada (ClampingScrollPhysics) 