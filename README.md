# RouteGuard — Aplicación Multiplataforma (Cross-Platform)

[![Flutter](https://img.shields.io/badge/Flutter-3.47.8-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.13.7-0175C2?logo=dart)](https://dart.dev)
[![Architecture](https://img.shields.io/badge/Architecture-Clean%20%2F%20Feature--First-blue)]()
[![License](https://img.shields.io/badge/License-MIT-green.svg)]()

> **Universidad Peruana de Ciencias Aplicadas (UPC)**  
> **Carrera:** Ingeniería de Software  
> **Curso:** Aplicaciones para Dispositivos Móviles (1ACC0238) — Periodo 2026-20  
> **Equipo:** RouteGolem  
> **Hito:** AV2 (Semana 12 / Sprint 2)

---

## 1. Descripción del Proyecto

**RouteGuard Cross-Platform App** es la aplicación móvil multiplataforma desarrollada en **Flutter** orientada al segmento objetivo de **Padres de Familia / Apoderados**. Permite a los padres monitorear en tiempo real la ruta del transporte escolar de sus hijos, recibir alertas automáticas de abordaje y llegada a la institución educativa, visualizar la telemetría del viaje (velocidad del bus, estado de la ruta y tiempo estimado de llegada - ETA) y gestionar su perfil de usuario con mecanismos de autenticación y cierre seguro de sesión.

---

## 2. Características Principales

1. **Autenticación y Seguridad (IAM):**
   - Inicio de sesión conectado a la API RESTful de RouteGuard (`routeguard-web-services`).
   - Persistencia de sesión local segura mediante `shared_preferences`.
   - Soporte offline y credenciales demo preconfiguradas para evaluación.
2. **Seguimiento en Vivo (Live Tracking):**
   - Mapa interactivo OpenStreetMap implementado con `flutter_map` y `latlong2`.
   - Marcadores dinámicos diferenciados: Unidad de transporte escolar y paraderos de estudiantes.
   - Trazado de ruta optimizada (*polyline*).
   - Panel inferior con telemetría en tiempo real: Conductor asignado, velocidad actual (km/h) y estado operativo.
3. **Centro de Notificaciones y Alertas:**
   - Registro cronológico de eventos críticos: Abordaje del menor, alertas de tráfico severo y confirmación de llegada segura al colegio.
4. **Gestión de Perfil de Usuario:**
   - Visualización de datos del apoderado y estudiante asignado.
   - Cierre de sesión con diálogo modal de confirmación (*AlertDialog*) para prevenir abandonos accidentales, conforme a las heurísticas de Nielsen.

---

## 3. Estructura del Proyecto

El proyecto sigue una arquitectura **Feature-First / Clean Architecture**:

```text
lib/
├── core/
│   ├── constants/
│   │   └── api_constants.dart       # Configuración de URLs del backend
│   ├── theme/
│   │   └── app_theme.dart           # Diseño Material 3, paleta de colores y estilos
│   └── utils/
│       └── session_manager.dart     # Gestión de sesión local persistente
├── features/
│   ├── auth/                        # Módulo de Autenticación
│   │   ├── data/
│   │   ├── models/
│   │   └── presentation/
│   ├── tracking/                    # Módulo de Seguimiento GPS en Vivo
│   │   ├── data/
│   │   ├── models/
│   │   └── presentation/
│   ├── alerts/                      # Módulo de Notificaciones y Avisos
│   │   ├── models/
│   │   └── presentation/
│   └── profile/                     # Módulo de Perfil y Cierre de Sesión
│       └── presentation/
├── main_shell.dart                  # Navegación con BottomNavigationBar
└── main.dart                        # Punto de entrada de la aplicación
```

---

## 4. Requisitos y Configuración de Ejecución

### Prerrequisitos:
- Flutter SDK `>= 3.47.0`
- Dart SDK `>= 3.13.0`
- Dispositivo Android (emulador o físico con depuración USB) o navegador Web.

### Comandos de Instalación y Ejecución:

```bash
# 1. Obtener dependencias
flutter pub get

# 2. Ejecutar análisis estático de código
flutter analyze

# 3. Ejecutar suite de pruebas unitarias y de widgets
flutter test

# 4. Iniciar la aplicación
flutter run
```

---

## 5. Integrantes del Equipo (RouteGolem)

| Nombre Completo | Código de Estudiante | Rol / Responsabilidad en Sprint 2 |
| :--- | :--- | :--- |
| **Marcelo Pareja** | u202112345 | Core Architecture, Auth Module & Validation Video |
| **Mathias De la Cruz** | u202118765 | Live Tracking Module, Mapbox/OSM Integration & Product Video |
| **Jhony Francia** | u202213456 | Data Repositories, REST Client Integration & Team Video |
| **Nickolas Ramirez** | u202215678 | Alerts & Profile Modules, Unit/Widget Testing Suite |

---
© 2026 RouteGolem — Todos los derechos reservados.
