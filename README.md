# RouteGuard — Aplicación Multiplataforma (Cross-Platform)

[![Flutter](https://img.shields.io/badge/Flutter-Material_3-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.13.7-0175C2?logo=dart)](https://dart.dev)
[![Maps](https://img.shields.io/badge/Maps-flutter__map_%2B_OSM-7EBC6F?logo=openstreetmap)](https://www.openstreetmap.org)
[![i18n](https://img.shields.io/badge/i18n-ES_%2F_EN_Reactivo-00897B)](#)
[![Architecture](https://img.shields.io/badge/Architecture-Clean_%2F_Feature--First-blue)](#)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](#)

> **Universidad Peruana de Ciencias Aplicadas (UPC)**  
> **Carrera:** Ingeniería de Software  
> **Curso:** Aplicaciones para Dispositivos Móviles (1ACC0238) — Periodo 2026-20  
> **Equipo:** RouteGolem

---

## 1. Descripción del Proyecto

**RouteGuard Cross-Platform App** es la aplicación móvil multiplataforma desarrollada en **Flutter** con soporte completo para los **3 roles del ecosistema** (**Apoderado**, **Conductor** y **Administrador / Dueño**). Permite gestionar personal y grupos escolares, definir rutas y paradas en el mapa, monitorear la flota y telemetría en vivo, registrar el abordaje de estudiantes con deshacer/rectificar, enviar avisos y alertas de pánico, llamar directamente al conductor y cambiar el idioma de toda la aplicación entre español e inglés en tiempo real.

---

## 2. Stack Tecnológico & Librerías Usadas

| Capa / Funcionalidad | Tecnología / Paquete (`pubspec.yaml`) | Uso real en el proyecto |
| :--- | :--- | :--- |
| **Lenguaje y UI** | `Dart ^3.13.7` + `Flutter` (`Material 3`, `cupertino_icons ^1.0.8`) | Interfaz unificada Material 3, navegación multi-rol en `MainShell` y guía interactiva con asistente (`AssistantGuideOverlay`). |
| **Gestión de Estado** | Nativo de Flutter (`StatefulWidget`, `ValueNotifier`, `ValueListenableBuilder`) | Estado reactivo por pantalla y actualización instantánea de idioma y rol sin librerías externas (sin Bloc/Riverpod). |
| **Red / API REST** | `http ^1.6.0` | Conexión REST con `https://routeguard-web-services.onrender.com/api/v1` (y soporte local `10.0.2.2:5000`) con respaldo demo offline. |
| **Persistencia Local** | `shared_preferences ^2.5.6` | `SessionManager` persiste sesión/JWT, rol activo, teléfono, ruta local de avatar, tutorial visto e idioma (`app_language`). *(No usa SQLite/Room)*. |
| **Mapas y Coordenadas** | `flutter_map ^8.3.2` + `latlong2 ^0.10.1` + **OpenStreetMap** | Tiles `tile.openstreetmap.org`, marcadores diferenciados y trazado de rutas en Seguimiento, Conductor, Flota y Monitor en vivo. |
| **Cámara y Galería** | `image_picker ^1.2.4` | Selección o captura de foto de perfil desde cámara o galería/archivos del dispositivo. |
| **Llamadas y Enlaces** | `url_launcher ^6.3.3` | Apertura directa del marcador telefónico nativo (`tel:...`) desde el botón **Llamar al conductor**. |
| **Internacionalización** | `intl ^0.20.3` + `AppStrings` (`ValueNotifier`) | Diccionario bilingüe completo **ES / EN** (>200 claves) con cambio reactivo desde Perfil. |
| **Pasarela de Pago (UI)** | Checkout Modal personalizado en Flutter | Flujo visual de checkout mensual estilo Stripe Sandbox (`Básico`, `Familiar`, `Institucional`); simulado en cliente sin `flutter_stripe`. |
| **Calidad & Testing** | `flutter_lints ^6.0.0` + `flutter_test` | Análisis estático limpio y suite de 43 pruebas unitarias y de widgets (incluyendo paridad ES/EN y pruebas de layout multi-rol). |

---

## 3. Características Principales por Rol

1. **Autenticación, Demo Multi-Rol y Asistente Interactivo:**
   - Inicio de sesión REST / offline con accesos rápidos demo para Apoderado, Conductor y Administrador, recuperación de contraseña y registro modal con Términos y Condiciones.
   - Tutorial interactivo paso a paso adaptado al rol activo.
2. **Apoderado (Seguimiento en Vivo y Seguridad):**
   - Mapa en tiempo real (`flutter_map` + OpenStreetMap) con leyenda, ficha de vehículo y seguridad, próxima parada, estado de hijos y botón **Llamar al conductor** vía `url_launcher`.
   - Red de cuidadores autorizados en Perfil.
3. **Conductor (Recorrido y Alertas):**
   - Mapa de recorrido, selector de paradas, checklist de abordaje (`Subió`, `No asistió`, más deshacer/rectificar), confirmación masiva de llegada al colegio, reporte de incidencias y publicación de avisos o alertas de pánico.
4. **Administrador / Dueño (Gestión Integral):**
   - Pestaña **Personas**: gestión y registro de conductores, padres, estudiantes y grupos escolares.
   - Pestaña **Rutas**: creación, buscador por nombre y editor de paradas en mapa.
   - Pestaña **En vivo**: monitor simultáneo de unidades activas con ocupación y telemetría.
   - Pestaña **Planes**: suscripciones y modal de checkout estilo Stripe.
5. **Perfil Universal:**
   - Cambio de rol demo, selector reactivo de idioma **ES / EN**, actualización de foto de perfil con cámara o galería (`image_picker`), acceso a la guía y cierre de sesión con confirmación.

---

## 4. Estructura del Proyecto

El proyecto sigue una arquitectura **Feature-First**:

```text
lib/
├── core/
│   ├── assistant/                   # Guía interactiva y pasos por rol
│   ├── constants/api_constants.dart # URLs base y endpoints REST
│   ├── localization/app_strings.dart# Diccionario ES/EN reactivo (AppStrings)
│   ├── theme/app_theme.dart         # Tema Material 3 y paleta corporativa
│   └── utils/session_manager.dart   # Persistencia local (shared_preferences)
├── features/
│   ├── auth/                        # Login, registro y modelos de cuenta
│   ├── stakeholders/                # Conductores, padres, alumnos y grupos
│   ├── fleet/                       # Planificador de rutas y detalle en mapa
│   ├── driver/                      # Recorrido del conductor e incidencias
│   ├── monitor/                     # Monitoreo en vivo de toda la flota
│   ├── tracking/                    # Seguimiento GPS del apoderado + llamada
│   ├── alerts/                      # Centro de alertas, avisos y pánico
│   ├── subscription/                # Planes y checkout estilo Stripe
│   └── profile/                     # Perfil, foto (cámara/galería), idioma y cuidadores
├── main_shell.dart                  # Navegación inferior adaptativa por rol
└── main.dart                        # Punto de entrada y listener global de idioma
```

---

## 5. Requisitos y Comandos de Ejecución

### Prerrequisitos
- Flutter SDK / Dart SDK `^3.13.7`
- Dispositivo Android (emulador o físico con depuración USB) o plataforma compatible.

### Comandos
```bash
# 1. Instalar dependencias
flutter pub get

# 2. Ejecutar análisis estático de código
flutter analyze

# 3. Ejecutar pruebas unitarias y de widgets
flutter test

# 4. Compilar / ejecutar la aplicación
flutter run
```

---

## 6. Integrantes del Equipo (RouteGolem)

| Nombre Completo | Código de Estudiante | Rol / Responsabilidad |
| :--- | :--- | :--- |
| **Marcelo Pareja** | u202112345 | Core Architecture, Auth Module & Validation |
| **Mathias De la Cruz** | u202118765 | Live Tracking Module & Map Integration |
| **Jhony Francia** | u202213456 | Data Repositories & REST Client Integration |
| **Nickolas Ramirez** | u202215678 | Alerts, Profile Modules & Testing Suite |

---
© 2026 RouteGolem — Todos los derechos reservados.
